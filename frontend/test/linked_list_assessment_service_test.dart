import 'package:flutter_test/flutter_test.dart';
import 'package:ar_stem_learning_prototype/features/assessments/linked_list_assessment/models/linked_list_graph.dart';
import 'package:ar_stem_learning_prototype/features/assessments/linked_list_assessment/services/linked_list_assessment_service.dart';

void main() {
  late LinkedListAssessmentService service;

  setUp(() => service = LinkedListAssessmentService());

  // ── Helpers ───────────────────────────────────────────────────────────────

  LinkedListGraph fullGraph() => LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 2, 2: 3, 3: 4, 4: null},
        headId: 1,
      );

  /// 4-node broken graph (used for generic validateRepair edge-case tests).
  LinkedListGraph brokenGraph() => LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 2, 2: null, 3: 4, 4: null},
        headId: 1,
      );

  // ── Challenge 2 specific helpers (3-node list) ────────────────────────────

  /// The exact initialGraph used in Challenge 2.
  /// HEAD → 10 → 25 → [BROKEN]    40 (isolated tail)
  LinkedListGraph challenge2Initial() => LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40'},
        nextPointers: {1: 2, 2: null, 3: null},
        headId: 1,
      );

  /// The exact expectedGraph used in Challenge 2.
  /// HEAD → 10 → 25 → 40 → null
  LinkedListGraph challenge2Expected() => LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40'},
        nextPointers: {1: 2, 2: 3, 3: null},
        headId: 1,
      );

  LinkedListGraph emptyGraph() => LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: null, 2: null, 3: null, 4: null},
        headId: null,
      );

  // ── validateBuild ─────────────────────────────────────────────────────────

  group('validateBuild', () {
    test('passes when graph matches expected exactly', () {
      final result = service.validateBuild(fullGraph(), fullGraph());
      expect(result.isValid, isTrue);
      expect(result.misconceptionCode, isNull);
    });

    test('fails with HEAD_POINTER_MISSING when no head assigned', () {
      final result = service.validateBuild(emptyGraph(), fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_HEAD_POINTER_MISSING'));
    });

    test('fails when head is wrong node', () {
      final wrongHead = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 2, 2: 3, 3: 4, 4: null},
        headId: 2, // wrong — expected headId is 1
      );
      final result = service.validateBuild(wrongHead, fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_HEAD_POINTER_MISSING'));
    });

    test('fails with BROKEN_LINKED_LIST when isolated nodes exist', () {
      final partial = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 2, 2: null, 3: null, 4: null},
        headId: 1,
      );
      final result = service.validateBuild(partial, fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_BROKEN_LINKED_LIST'));
    });

    test('fails with INVALID_TRAVERSAL when order is wrong', () {
      final wrongOrder = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 3, 3: 2, 2: 4, 4: null}, // wrong sequence
        headId: 1,
      );
      final result = service.validateBuild(wrongOrder, fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_INVALID_TRAVERSAL'));
    });
  });

  // ── validateRepair ────────────────────────────────────────────────────────
  //
  // Challenge 2 uses a 3-node graph: {1:'10', 2:'25', 3:'40'}
  // initialGraph : head=1, 1→2, 2→null, 3→null   (node 3 is isolated)
  // expectedGraph: head=1, 1→2, 2→3,    3→null   (fully connected)

  group('validateRepair — Challenge 2 graphs', () {
    test('passes when the correct pointer 2→3 is added', () {
      final result = service.validateRepair(
        challenge2Expected(),
        challenge2Expected(),
      );
      expect(result.isValid, isTrue);
      expect(result.misconceptionCode, isNull);
    });

    test('fails with BROKEN_LINKED_LIST on initialGraph (link not yet added)', () {
      final result = service.validateRepair(
        challenge2Initial(),
        challenge2Expected(),
      );
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_BROKEN_LINKED_LIST'));
      // Hint should mention node label '40' (id 3) as disconnected.
      expect(result.hint, contains('40'));
    });

    test('fails with BROKEN_LINKED_LIST when wrong pointer drawn (2→1 instead of 2→3)', () {
      // Student connected 25→10 (backwards) — node 3 still isolated.
      final wrongRepair = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40'},
        nextPointers: {1: 2, 2: 1, 3: null},
        headId: 1,
      );
      final result = service.validateRepair(wrongRepair, challenge2Expected());
      expect(result.isValid, isFalse);
      // Node 3 unreachable → cycle detection not needed; node 3 isolated.
      expect(result.misconceptionCode, equals('DSA_BROKEN_LINKED_LIST'));
    });

    test('fails with INVALID_TRAVERSAL when all nodes connected but in wrong order', () {
      // Student connected 1→3→2 instead of 1→2→3.
      final wrongOrder = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40'},
        nextPointers: {1: 3, 3: 2, 2: null},
        headId: 1,
      );
      final result = service.validateRepair(wrongOrder, challenge2Expected());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_INVALID_TRAVERSAL'));
    });

    test('fails with HEAD_POINTER_MISSING when head is altered', () {
      final alteredHead = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40'},
        nextPointers: {1: 2, 2: 3, 3: null},
        headId: 2, // changed from 1
      );
      final result = service.validateRepair(alteredHead, challenge2Expected());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_HEAD_POINTER_MISSING'));
    });
  });

  group('validateRepair — generic edge cases (4-node)', () {
    test('fails with BROKEN_LINKED_LIST when link is still missing', () {
      final result = service.validateRepair(brokenGraph(), fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_BROKEN_LINKED_LIST'));
    });

    test('fails with BROKEN_LINKED_LIST when wrong nodes connected (node 3 isolated)', () {
      final wrongRepair = LinkedListGraph(
        nodes: {1: '10', 2: '25', 3: '40', 4: '60'},
        nextPointers: {1: 2, 2: 4, 3: null, 4: null},
        headId: 1,
      );
      final result = service.validateRepair(wrongRepair, fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_BROKEN_LINKED_LIST'));
    });
  });

  // ── validateTraversal ─────────────────────────────────────────────────────

  group('validateTraversal', () {
    test('passes when full sequence matches traversalOrder', () {
      final result = service.validateTraversal([1, 2, 3, 4], fullGraph());
      expect(result.isValid, isTrue);
    });

    test('fails with empty sequence', () {
      final result = service.validateTraversal([], fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, isNull);
    });

    test('returns partial progress hint mid-traversal', () {
      final result = service.validateTraversal([1, 2], fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, isNull); // no misconception yet
    });
  });

  // ── validateNextTap ───────────────────────────────────────────────────────

  group('validateNextTap', () {
    test('correct first tap (HEAD)', () {
      final result = service.validateNextTap(1, [], fullGraph());
      expect(result.isValid, isTrue);
    });

    test('wrong first tap triggers INVALID_TRAVERSAL', () {
      final result = service.validateNextTap(3, [], fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_INVALID_TRAVERSAL'));
    });

    test('correct second tap', () {
      final result = service.validateNextTap(2, [1], fullGraph());
      expect(result.isValid, isTrue);
    });

    test('wrong mid-sequence tap triggers INVALID_TRAVERSAL', () {
      final result = service.validateNextTap(4, [1, 2], fullGraph());
      expect(result.isValid, isFalse);
      expect(result.misconceptionCode, equals('DSA_INVALID_TRAVERSAL'));
    });
  });

  // ── toResult / buildResult ────────────────────────────────────────────────

  group('toResult and buildResult', () {
    test('toResult awards full points on valid result', () {
      final vr = service.validateBuild(fullGraph(), fullGraph());
      final cr = service.toResult(vr, 35);
      expect(cr.passed, isTrue);
      expect(cr.score, equals(35));
    });

    test('toResult awards zero points on invalid result', () {
      final vr = service.validateBuild(emptyGraph(), fullGraph());
      final cr = service.toResult(vr, 35);
      expect(cr.passed, isFalse);
      expect(cr.score, equals(0));
    });

    test('buildResult sums scores correctly', () {
      final r1 = service.toResult(
          service.validateBuild(fullGraph(), fullGraph()), 35);
      final r2 = service.toResult(
          service.validateRepair(fullGraph(), fullGraph()), 35);
      final r3 = service.toResult(
          service.validateTraversal([1, 2, 3, 4], fullGraph()), 30);
      final summary = service.buildResult([r1, r2, r3]);
      expect(summary.totalScore, equals(100));
      expect(summary.passedChallenges, equals(3));
    });
  });
}
