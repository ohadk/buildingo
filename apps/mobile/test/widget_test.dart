import 'package:flutter_test/flutter_test.dart';
import 'package:dira_mobile/core/models.dart';

void main() {
  test('Ticket parses timeline events from API payload', () {
    final ticket = Ticket.fromJson({
      'id': 't1',
      'title': 'Elevator outage',
      'description': 'Stuck between floors 2-3',
      'status': 'in_progress',
      'agent_status': 'resolved',
      'created_at': '2026-08-25T08:00:00Z',
      'ticket_events': [
        {'label': 'Reported', 'detail': null, 'created_at': '2026-08-25T08:00:00Z'},
        {
          'label': 'Agent Contacted Vendor',
          'detail': 'Otis Elevator Co via email',
          'created_at': '2026-08-25T08:05:00Z'
        },
      ],
    });

    expect(ticket.events.length, 2);
    expect(ticket.events.last.label, 'Agent Contacted Vendor');
    expect(ticket.status, 'in_progress');
  });
}
