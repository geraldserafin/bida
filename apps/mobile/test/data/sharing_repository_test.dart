import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/data/sharing_repository.dart';
import 'package:money_planner/models/models.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late SharingRepository repository;

  setUp(() {
    backend = FakeBackend();
    repository = SharingRepository(backend.dio());
  });

  test('lists the budgets with the kind and the role of the user', () async {
    backend.on(
      'GET /spaces',
      (_) => Reply([
        mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
        mySpaceJson(
          's2',
          'Dom',
          role: 'member',
          memberCount: 3,
          currency: 'EUR',
        ),
      ]),
    );

    final spaces = await repository.spaces();

    expect(spaces.map((s) => s.name), ['Mój budżet', 'Dom']);
    expect(spaces[0].kind, SpaceKind.personal);
    expect(spaces[0].isShared, isFalse);
    expect(spaces[0].isOwner, isTrue);
    expect(spaces[1].isShared, isTrue);
    expect(spaces[1].role, SpaceRole.member);
    expect(spaces[1].memberCount, 3);
    expect(spaces[1].currency, 'EUR');
  });

  test('creates and edits a shared budget', () async {
    backend.on(
      'POST /spaces',
      (_) => Reply(mySpaceJson('s2', 'Dom'), status: 201),
    );
    backend.on('PUT /spaces/s2', (_) => Reply(mySpaceJson('s2', 'Flat')));

    final created = await repository.createSpace('Dom', 'PLN');
    final renamed = await repository.updateSpace('s2', 'Flat', 'EUR');

    expect(created.id, 's2');
    expect(renamed.name, 'Flat');
    expect(backend.sent('POST /spaces').single.body, {
      'name': 'Dom',
      'defaultCurrency': 'PLN',
    });
    expect(backend.sent('PUT /spaces/s2').single.body, {
      'name': 'Flat',
      'defaultCurrency': 'EUR',
    });
  });

  test('members come with their names, or just the address', () async {
    backend.on(
      'GET /spaces/s2/members',
      (_) => Reply([
        memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
        memberJson('u2', 'bob@example.com'),
      ]),
    );

    final members = await repository.members('s2');

    expect(members.map((m) => m.label), ['Ann', 'bob@example.com']);
    expect(members[0].role, SpaceRole.owner);
    expect(members[1].role, SpaceRole.member);
  });

  test('changes a role and removes a member', () async {
    backend.on(
      'PUT /spaces/s2/members/u2',
      (_) => Reply(memberJson('u2', 'bob@example.com', role: 'owner')),
    );
    backend.on(
      'DELETE /spaces/s2/members/u3',
      (_) => const Reply(null, status: 204),
    );

    await repository.setRole('s2', 'u2', SpaceRole.owner);
    await repository.removeMember('s2', 'u3');

    expect(backend.sent('PUT /spaces/s2/members/u2').single.body, {
      'role': 'owner',
    });
    expect(backend.sent('DELETE /spaces/s2/members/u3'), hasLength(1));
  });

  test('an invitation goes out by e-mail with a role', () async {
    backend.on(
      'POST /spaces/s2/invitations',
      (_) => Reply(invitationJson('i1'), status: 201),
    );

    final invitation = await repository.invite(
      's2',
      'bob@example.com',
      SpaceRole.member,
    );

    expect(invitation.id, 'i1');
    expect(invitation.status, InvitationStatus.invited);
    expect(invitation.invitedBy, 'Ann');
    expect(backend.sent('POST /spaces/s2/invitations').single.body, {
      'email': 'bob@example.com',
      'role': 'member',
    });
  });

  test('my invitations can be accepted and declined', () async {
    backend.on('GET /invitations', (_) => Reply([invitationJson('i1')]));
    backend.on(
      'POST /invitations/i1/accept',
      (_) => Reply(invitationJson('i1', status: 'accepted')),
    );
    backend.on(
      'POST /invitations/i2/decline',
      (_) => const Reply(null, status: 204),
    );

    expect((await repository.myInvitations()).single.spaceName, 'Dom');
    await repository.acceptInvitation('i1');
    await repository.declineInvitation('i2');

    expect(backend.sent('POST /invitations/i1/accept'), hasLength(1));
    expect(backend.sent('POST /invitations/i2/decline'), hasLength(1));
  });

  test('owners see, approve and revoke the open invitations', () async {
    backend.on(
      'GET /spaces/s2/invitations',
      (_) => Reply([invitationJson('i1', status: 'accepted')]),
    );
    backend.on(
      'POST /spaces/s2/invitations/i1/approve',
      (_) => Reply(memberJson('u2', 'bob@example.com')),
    );
    backend.on(
      'DELETE /spaces/s2/invitations/i3',
      (_) => const Reply(null, status: 204),
    );

    final open = await repository.spaceInvitations('s2');
    await repository.approveInvitation('s2', 'i1');
    await repository.revokeInvitation('s2', 'i3');

    expect(open.single.status, InvitationStatus.accepted);
    expect(
      backend.sent('POST /spaces/s2/invitations/i1/approve'),
      hasLength(1),
    );
    expect(backend.sent('DELETE /spaces/s2/invitations/i3'), hasLength(1));
  });

  test('contributions are in whole units of the period currency', () async {
    backend.on(
      'GET /periods/p1/contributions',
      (_) => Reply([contributionJson('k1', 300000, userId: 'u1')]),
    );
    backend.on(
      'POST /periods/p1/contributions',
      (_) => Reply(contributionJson('k2', 5000), status: 201),
    );

    final list = await repository.contributions('p1', 'PLN');
    await repository.addContribution(
      'p1',
      amount: 50,
      currency: 'PLN',
      date: DateTime.utc(2026, 7, 2, 10),
      note: 'gotówka',
      external: true,
    );

    expect(list.single.amount, 3000);
    expect(list.single.userId, 'u1');
    expect(backend.sent('POST /periods/p1/contributions').single.body, {
      'amountMinor': 5000,
      'contributedAt': '2026-07-02T10:00:00.000Z',
      'note': 'gotówka',
      'external': true,
    });
  });

  test('a refusal for members is its own failure', () async {
    backend.on('PUT /spaces/s2', (_) => Reply.error(403, 'Forbidden'));

    await expectLater(
      repository.updateSpace('s2', 'x', 'PLN'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.forbidden,
        ),
      ),
    );
  });
}
