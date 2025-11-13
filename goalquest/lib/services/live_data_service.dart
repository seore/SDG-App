import 'dart:async';

class LiveMissionCompletion {
  final String userName;
  final String missionTitle;
  final int sdgNumber;
  final DateTime timestamp;

  LiveMissionCompletion({
    required this.userName,
    required this.missionTitle,
    required this.sdgNumber,
    required this.timestamp,
  });
}

class CommunityStory {
  final String userName;
  final String message;
  final int? sdgNumber;
  final DateTime createdAt;

  CommunityStory({
    required this.userName,
    required this.message,
    this.sdgNumber,
    required this.createdAt,
  });
}

class LiveDataService {
  // Singleton
  static final LiveDataService instance = LiveDataService._internal();
  LiveDataService._internal();

  final _completionsController =
      StreamController<List<LiveMissionCompletion>>.broadcast();
  final _storiesController =
      StreamController<List<CommunityStory>>.broadcast();

  final List<LiveMissionCompletion> _completions = [];
  final List<CommunityStory> _stories = [];

  Stream<List<LiveMissionCompletion>> get completionsStream =>
      _completionsController.stream;

  Stream<List<CommunityStory>> get storiesStream =>
      _storiesController.stream;

  void addCompletion(LiveMissionCompletion completion) {
    _completions.insert(0, completion); 
    _completionsController.add(List.unmodifiable(_completions));
  }

  void addStory(CommunityStory story) {
    _stories.insert(0, story);
    _storiesController.add(List.unmodifiable(_stories));
  }

  void seedDemoData() {
    addCompletion(
      LiveMissionCompletion(
        userName: 'Amina',
        missionTitle: 'Plastic-Free Day',
        sdgNumber: 12,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
    addCompletion(
      LiveMissionCompletion(
        userName: 'Leo',
        missionTitle: 'Unplug devices for 1 hour',
        sdgNumber: 7,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    );
    addStory(
      CommunityStory(
        userName: 'Amina',
        message:
            'Our class cleaned up the school playground and sorted all the trash!',
        sdgNumber: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
    addStory(
      CommunityStory(
        userName: 'Leo',
        message:
            'I convinced my family to switch to reusable water bottles 💧',
        sdgNumber: 6,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    );
  }
}
