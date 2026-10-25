import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/active_space.dart';
import 'package:money_planner/data/sharing_repository.dart';
import 'package:money_planner/models/models.dart';
import 'package:money_planner/state/spaces_state.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late ActiveSpace active;
  late SpacesState state;
  var spaces = <Map<String, Object?>>[];

  Future<void> signIn() async {
    state.bind(signedIn: true);
    await Future<void>.delayed(Duration.zero);
    await state.load(); // wait for the load that started
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend();
    active = ActiveSpace();
    spaces = [
      mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
      mySpaceJson('s2', 'Dom', role: 'member', memberCount: 2),
    ];
    backend.on('GET /spaces', (_) => Reply(spaces));
    backend.on('GET /invitations', (_) => Reply([invitationJson('i1')]));
    state = SpacesState(SharingRepository(backend.dio()), active);
  });

  tearDown(() => state.dispose());

  test('starts in the personal budget and knows the invitations', () async {
    await signIn();

    expect(state.spaces.map((s) => s.name), ['Mój budżet', 'Dom']);
    expect(state.current?.id, 's1');
    expect(active.id, 's1');
    expect(state.invitations.map((i) => i.id), ['i1']);
    expect(state.isLoading, isFalse);
  });

  test('remembers the budget that was chosen', () async {
    await signIn();
    await state.select('s2');
    expect(state.current?.id, 's2');
    expect(state.current?.role, SpaceRole.member);
    expect(active.id, 's2');

    // the next start opens in the same budget
    final next = SpacesState(SharingRepository(backend.dio()), ActiveSpace());
    addTearDown(next.dispose);
    await next.load();
    expect(next.current?.id, 's2');
  });

  test(
    'a remembered budget that is gone falls back to the personal one',
    () async {
      FlutterSecureStorage.setMockInitialValues({'current_space_id': 'gone'});

      await signIn();

      expect(state.current?.id, 's1');
    },
  );

  test('creating a shared budget switches to it', () async {
    backend.on(
      'POST /spaces',
      (_) => Reply(mySpaceJson('s3', 'Wakacje'), status: 201),
    );

    await signIn();
    await state.createShared('Wakacje', 'PLN');

    expect(state.spaces.map((s) => s.id), ['s1', 's2', 's3']);
    expect(state.current?.id, 's3');
    expect(state.isOwner, isTrue);
  });

  test('leaving the budget in use goes back to the personal one', () async {
    backend.on('POST /spaces/s2/leave', (_) => const Reply(null, status: 204));

    await signIn();
    await state.select('s2');
    await state.leave(state.current!);

    expect(state.spaces.map((s) => s.id), ['s1']);
    expect(state.current?.id, 's1');
    expect(active.id, 's1');
  });

  test('being removed from the budget in use is noticed once', () async {
    await signIn();
    await state.select('s2');

    // the server no longer lists it
    spaces = [mySpaceJson('s1', 'Mój budżet', kind: 'personal')];
    active.missing();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(state.current?.id, 's1');
    expect(state.removedFrom, 'Dom');
    state.clearRemovedNotice();
    expect(state.removedFrom, isNull);
  });

  test('an invitation is answered and leaves the list', () async {
    backend.on(
      'POST /invitations/i1/accept',
      (_) => Reply(invitationJson('i1', status: 'accepted')),
    );

    await signIn();
    await state.answerInvitation(state.invitations.single, accept: true);

    expect(state.invitations, isEmpty);
    expect(backend.sent('POST /invitations/i1/accept'), hasLength(1));
  });

  test('forgets everything when the user signs out', () async {
    await signIn();

    state.bind(signedIn: false);
    await Future<void>.delayed(Duration.zero);

    expect(state.spaces, isEmpty);
    expect(state.current, isNull);
    expect(active.id, isNull);
  });

  test('a failed load keeps the reason', () async {
    backend.on('GET /spaces', (_) => const Reply.unreachable());

    await signIn();

    expect(state.loadError, isNotNull);
    expect(state.current, isNull);
  });
}
