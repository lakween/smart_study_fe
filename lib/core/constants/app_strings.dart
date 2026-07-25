class AppStrings {
  AppStrings._();

  static const String appName = 'Smart Study';
  static const String tagline = 'Learn Smarter, Not Harder';

  // Auth
  static const String welcomeBack = 'Welcome Back';
  static const String welcomeBackSubtitle = 'Sign in to continue your learning journey';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String createAccount = 'Create Account';
  static const String createAccountSubtitle = 'Start your learning journey today';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String sendResetLink = 'Send Reset Link';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String university = 'University / Institute';
  static const String studyLevel = 'Study Level';
  static const String or = 'OR';

  // Study Levels
  static const List<String> studyLevels = [
    'School',
    'Undergraduate',
    'Postgraduate',
    'Self-learner',
  ];

  // Navigation
  static const String home = 'Home';
  static const String subjects = 'Subjects';
  static const String exams = 'Exams';
  static const String friends = 'Friends';
  static const String profile = 'Profile';

  // Subjects
  static const String mySubjects = 'My Subjects';
  static const String createSubject = 'Create Subject';
  static const String editSubject = 'Edit Subject';
  static const String subjectName = 'Subject Name';
  static const String description = 'Description';
  static const String visibility = 'Visibility';
  static const String allowCopy = 'Allow Copy';
  static const String allowCopyDescription = 'Allow other users to copy this content to their account';
  static const String noSubjectsYet = 'No subjects yet';
  static const String noSubjectsMessage = 'Create your first subject to start organizing your studies!';

  // Topics
  static const String topics = 'Topics';
  static const String createTopic = 'Create Topic';
  static const String editTopic = 'Edit Topic';
  static const String topicName = 'Topic Name';
  static const String noTopicsYet = 'No topics yet';
  static const String noTopicsMessage = 'Add topics to organize your subject content';

  // Documents
  static const String documents = 'Documents';
  static const String uploadDocument = 'Upload Document';
  static const String documentTitle = 'Document Title';
  static const String selectFile = 'Select File';
  static const String supportedTypes = 'Supported: PDF, JPG, PNG, JPEG (max 10MB)';

  // Quizzes
  static const String quizzes = 'Quizzes';
  static const String createQuiz = 'Create Quiz';
  static const String editQuiz = 'Edit Quiz';
  static const String quizTitle = 'Quiz Title';
  static const String timeLimit = 'Time Limit (minutes, optional)';
  static const String addQuestion = 'Add Question';
  static const String questionText = 'Question';
  static const String optionA = 'Option A';
  static const String optionB = 'Option B';
  static const String optionC = 'Option C';
  static const String optionD = 'Option D';
  static const String correctAnswer = 'Correct Answer';
  static const String explanation = 'Explanation (optional)';
  static const String practiceButton = 'Practice';
  static const String noQuizzesYet = 'No quizzes yet';
  static const String noQuizzesMessage = 'Create or discover quizzes to test your knowledge';

  // AI Quiz
  static const String aiQuizGenerator = 'AI Quiz Generator';
  static const String generateQuiz = 'Generate Quiz';
  static const String numberOfQuestions = 'Number of Questions';
  static const String reviewBeforeSaving = 'AI Generated — Please review before saving';

  // Exams
  static const String createExam = 'Create Exam';
  static const String examTitle = 'Exam Title';
  static const String duration = 'Duration';
  static const String startTime = 'Start Time';
  static const String inviteFriends = 'Invite Friends';
  static const String noExamsYet = 'No exams yet';

  // Friends
  static const String noFriendsYet = 'No friends yet';
  static const String noFriendsMessage = 'Search for people you know!';
  static const String friendRequests = 'Friend Requests';
  static const String findFriends = 'Find Friends';
  static const String addFriend = 'Add Friend';
  static const String pending = 'Pending';
  static const String removeFriend = 'Remove Friend';
  static const String accept = 'Accept';
  static const String decline = 'Decline';
  static const String cancelRequest = 'Cancel Request';

  // Notifications
  static const String notifications = 'Notifications';
  static const String markAllRead = 'Mark all as read';
  static const String allCaughtUp = "You're all caught up!";
  static const String noNotifications = 'No notifications right now';

  // Dashboard
  static const String myPerformance = 'My Performance';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String allTime = 'All Time';

  // Settings
  static const String settings = 'Settings';
  static const String changePassword = 'Change Password';
  static const String updateEmail = 'Update Email';
  static const String deleteAccount = 'Delete Account';
  static const String darkMode = 'Dark Mode';
  static const String fontSize = 'Font Size';
  static const String signOut = 'Sign Out';
  static const String signOutConfirm = 'Are you sure you want to sign out?';
  static const String appVersion = 'App Version';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';

  // Visibility
  static const String private = 'Private';
  static const String friendsOnly = 'Friends Only';
  static const String public = 'Public';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String close = 'Close';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String seeAll = 'See All';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String all = 'All';
  static const String submit = 'Submit';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String back = 'Back';
  static const String continueText = 'Continue';
  static const String discard = 'Discard';
  static const String preview = 'Preview';

  // Result
  static const String quizResult = 'Quiz Result';
  static const String examResult = 'Exam Result';
  static const String passed = 'Passed';
  static const String failed = 'Failed';
  static const String retryQuiz = 'Retry Quiz';
  static const String backToQuizzes = 'Back to Quizzes';
  static const String viewDashboard = 'View Dashboard';

  // Errors
  static const String somethingWentWrong = 'Something went wrong';
  static const String checkConnection = 'Please check your connection and try again';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordWeak = 'Password must contain a letter and a number';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String nameRequired = 'Name is required';
  static const String nameTooShort = 'Name must be at least 2 characters';
  static const String subjectNameRequired = 'Subject name is required';
  static const String subjectNameTooShort = 'Subject name must be at least 2 characters';
  static const String quizTitleRequired = 'Quiz title is required';
  static const String questionRequired = 'Question text is required';
  static const String optionRequired = 'All options are required';
  static const String atLeastOneQuestion = 'Add at least one question';
}
