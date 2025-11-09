import 'dart:async';
import 'dart:math';
import 'agent_types.dart' as agent_types;

/// Memory system for autonomous agents
class AgentMemorySystem {
  final List<agent_types.AgentMemoryEntry> _memories = [];
  Map<String, List<agent_types.AgentMemoryEntry>> _semanticIndex = {};
  final int _maxMemories;
  final double _relevanceThreshold;

  AgentMemorySystem({
    int maxMemories = 1000,
    double relevanceThreshold = 0.5,
  })  : _maxMemories = maxMemories,
        _relevanceThreshold = relevanceThreshold;

  /// Store an execution in memory
  Future<void> storeExecution({
    required String executionId,
    required String goal,
    required List<agent_types.AgentStep> steps,
    required String result,
  }) async {
    // Store conversation memory
    await addMemory(
      type: agent_types.AgentMemoryType.conversation,
      content: 'Goal: $goal\nResult: $result',
      metadata: {
        'executionId': executionId,
        'goal': goal,
        'stepsCount': steps.length,
        'success': steps.every((s) => s.error == null),
      },
    );

    // Store episodic memory (compressed execution)
    final episodicContent = _compressExecutionToEpisodic(goal, steps, result);
    await addMemory(
      type: agent_types.AgentMemoryType.episodic,
      content: episodicContent,
      metadata: {
        'executionId': executionId,
        'goal': goal,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Extract and store semantic memories
    await _extractAndStoreSemanticMemories(goal, steps, result);
  }

  /// Add a memory entry
  Future<void> addMemory({
    required agent_types.AgentMemoryType type,
    required String content,
    required Map<String, dynamic> metadata,
    double relevance = 1.0,
  }) async {
    final memory = agent_types.AgentMemoryEntry(
      id: _generateMemoryId(),
      type: type,
      content: content,
      metadata: metadata,
      timestamp: DateTime.now(),
      relevance: relevance,
    );

    _memories.add(memory);

    // Update semantic index
    if (type == agent_types.AgentMemoryType.semantic) {
      await _updateSemanticIndex(memory);
    }

    // Prune old memories if limit exceeded
    if (_memories.length > _maxMemories) {
      await _pruneMemories();
    }
  }

  /// Get relevant context for a given goal
  Future<String> getRelevantContext(String goal) async {
    final relevantMemories = await findRelevantMemories(goal, limit: 5);

    if (relevantMemories.isEmpty) {
      return 'No relevant memories found.';
    }

    return relevantMemories
        .map((m) => '[${m.type.name}] ${m.content}')
        .join('\n\n');
  }

  /// Find memories relevant to a query
  Future<List<agent_types.AgentMemoryEntry>> findRelevantMemories(
    String query, {
    int limit = 10,
    List<agent_types.AgentMemoryType>? types,
  }) async {
    // Filter by type if specified
    var candidateMemories = types != null
        ? _memories.where((m) => types.contains(m.type)).toList()
        : List<agent_types.AgentMemoryEntry>.from(_memories);

    // Simple keyword-based relevance scoring (can be enhanced with embeddings)
    final queryTerms = query.toLowerCase().split(' ');

    for (final memory in candidateMemories) {
      final content = memory.content.toLowerCase();
      var score = 0.0;

      for (final term in queryTerms) {
        if (term.length > 2 && content.contains(term)) {
          score += 1.0;
        }
      }

      // Boost score based on recency
      final ageInDays = DateTime.now().difference(memory.timestamp).inDays;
      final recencyBoost = 1.0 / (1.0 + ageInDays * 0.1);

      memory.relevance = score * recencyBoost * memory.relevance;
    }

    // Filter by threshold and sort by relevance
    candidateMemories
        .where((m) => m.relevance >= _relevanceThreshold)
        .toList()
        .sort((a, b) => b.relevance.compareTo(a.relevance));

    return candidateMemories
        .where((m) => m.relevance >= _relevanceThreshold)
        .take(limit)
        .toList();
  }

  /// Get memories by type
  List<agent_types.AgentMemoryEntry> getMemoriesByType(
      agent_types.AgentMemoryType type) {
    return _memories.where((m) => m.type == type).toList();
  }

  /// Get conversation history
  List<agent_types.AgentMemoryEntry> getConversationHistory({int limit = 50}) {
    return _memories
        .where((m) => m.type == agent_types.AgentMemoryType.conversation)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      ..take(limit);
  }

  /// Clear all memories
  Future<void> clearAll() async {
    _memories.clear();
    _semanticIndex.clear();
  }

  /// Export memories for persistence
  Map<String, dynamic> exportMemories() {
    return {
      'memories': _memories
          .map((m) => {
                'id': m.id,
                'type': m.type.name,
                'content': m.content,
                'metadata': m.metadata,
                'timestamp': m.timestamp.toIso8601String(),
                'relevance': m.relevance,
              })
          .toList(),
      'semanticIndex': _semanticIndex,
    };
  }

  /// Import memories from persisted data
  Future<void> importMemories(Map<String, dynamic> data) async {
    final memoriesData = data['memories'] as List;

    for (final memoryData in memoriesData) {
      _memories.add(agent_types.AgentMemoryEntry(
        id: memoryData['id'],
        type: agent_types.AgentMemoryType.values.firstWhere(
          (t) => t.name == memoryData['type'],
          orElse: () => agent_types.AgentMemoryType.conversation,
        ),
        content: memoryData['content'],
        metadata: Map<String, dynamic>.from(memoryData['metadata']),
        timestamp: DateTime.parse(memoryData['timestamp']),
        relevance: memoryData['relevance']?.toDouble() ?? 1.0,
      ));
    }

    _semanticIndex = Map<String, List<agent_types.AgentMemoryEntry>>.from(
      data['semanticIndex']?.map(
            (key, value) => MapEntry(
                key,
                value
                    .map((v) => agent_types.AgentMemoryEntry(
                          id: v['id'],
                          type: agent_types.AgentMemoryType.values.firstWhere(
                            (t) => t.name == v['type'],
                            orElse: () =>
                                agent_types.AgentMemoryType.conversation,
                          ),
                          content: v['content'],
                          metadata: Map<String, dynamic>.from(v['metadata']),
                          timestamp: DateTime.parse(v['timestamp']),
                          relevance: v['relevance']?.toDouble() ?? 1.0,
                        ))
                    .toList()),
          ) ??
          {},
    );
  }

  /// Compress execution to episodic memory
  String _compressExecutionToEpisodic(
    String goal,
    List<agent_types.AgentStep> steps,
    String result,
  ) {
    final successfulSteps = steps.where((s) => s.error == null).length;
    final failedSteps = steps.where((s) => s.error != null).length;
    final totalDuration =
        steps.fold(Duration.zero, (sum, step) => sum + step.duration);

    return 'Executed: "$goal" | Steps: $successfulSteps successful, $failedSteps failed | Duration: ${totalDuration.inSeconds}s | Result: $result';
  }

  /// Extract and store semantic memories
  Future<void> _extractAndStoreSemanticMemories(
    String goal,
    List<agent_types.AgentStep> steps,
    String result,
  ) async {
    // Extract key learnings from the execution
    final learnings = <String>[];

    // Look for patterns in successful steps
    final successfulToolSteps = steps
        .where((s) =>
            s.type == agent_types.AgentStepType.toolExecution &&
            s.error == null)
        .toList();

    for (final step in successfulToolSteps) {
      learnings.add('Successfully executed ${step.description}');
    }

    // Extract from reasoning steps
    final reasoningSteps = steps
        .where((s) => s.type == agent_types.AgentStepType.reasoning)
        .toList();

    for (final step in reasoningSteps) {
      if (step.output?['reasoning'] != null) {
        final reasoning = step.output!['reasoning'] as String;
        learnings.add(
            'Learned: ${reasoning.substring(0, min(100, reasoning.length))}');
      }
    }

    // Store each learning as a semantic memory
    for (final learning in learnings) {
      await addMemory(
        type: agent_types.AgentMemoryType.semantic,
        content: learning,
        metadata: {
          'sourceGoal': goal,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'extracted_learning',
        },
        relevance: 0.8,
      );
    }
  }

  /// Update semantic index for a memory
  Future<void> _updateSemanticIndex(agent_types.AgentMemoryEntry memory) async {
    // Simple keyword indexing (can be enhanced with embeddings)
    final words = memory.content.toLowerCase().split(' ');

    for (final word in words) {
      if (word.length > 3) {
        // Only index significant words
        _semanticIndex.putIfAbsent(word, () => []);
        _semanticIndex[word]!.add(memory);
      }
    }
  }

  /// Prune old memories when limit is exceeded
  Future<void> _pruneMemories() async {
    if (_memories.length <= _maxMemories) return;

    // Sort by relevance and recency, keeping the most valuable
    _memories.sort((a, b) {
      final scoreA = a.relevance *
          (1.0 / (1.0 + DateTime.now().difference(a.timestamp).inDays * 0.1));
      final scoreB = b.relevance *
          (1.0 / (1.0 + DateTime.now().difference(b.timestamp).inDays * 0.1));
      return scoreB.compareTo(scoreA);
    });

    // Remove oldest/least relevant memories
    _memories.removeRange(_maxMemories, _memories.length);

    // Update semantic index
    for (final word in _semanticIndex.keys.toList()) {
      _semanticIndex[word]!.removeWhere((m) => !_memories.contains(m));
      if (_semanticIndex[word]!.isEmpty) {
        _semanticIndex.remove(word);
      }
    }
  }

  /// Generate unique memory ID
  String _generateMemoryId() {
    return 'mem_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Get memory statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalMemories': _memories.length,
      'byType': {
        for (final type in agent_types.AgentMemoryType.values)
          type.name: _memories.where((m) => m.type == type).length,
      },
      'semanticIndexSize': _semanticIndex.length,
      'averageRelevance': _memories.isEmpty
          ? 0
          : _memories.map((m) => m.relevance).reduce((a, b) => a + b) /
              _memories.length,
    };
  }
}

/// Working memory for short-term context
class AgentWorkingMemory {
  final Map<String, dynamic> _context = {};
  final List<String> _conversationHistory = [];
  final int _maxHistoryLength;

  AgentWorkingMemory({int maxHistoryLength = 20})
      : _maxHistoryLength = maxHistoryLength;

  /// Set a value in working memory
  void setValue(String key, dynamic value) {
    _context[key] = value;
  }

  /// Get a value from working memory
  dynamic getValue(String key) {
    return _context[key];
  }

  /// Add to conversation history
  void addToConversation(String message) {
    _conversationHistory.add(message);
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
  }

  /// Get recent conversation
  List<String> getRecentConversation({int limit = 5}) {
    return _conversationHistory.reversed.take(limit).toList().reversed.toList();
  }

  /// Clear working memory
  void clear() {
    _context.clear();
    _conversationHistory.clear();
  }

  /// Export working memory state
  Map<String, dynamic> export() {
    return {
      'context': Map<String, dynamic>.from(_context),
      'conversationHistory': List<String>.from(_conversationHistory),
    };
  }

  /// Import working memory state
  void import(Map<String, dynamic> data) {
    _context.clear();
    _conversationHistory.clear();

    _context.addAll(Map<String, dynamic>.from(data['context'] ?? {}));
    _conversationHistory
        .addAll(List<String>.from(data['conversationHistory'] ?? []));
  }
}
