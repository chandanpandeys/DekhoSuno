/// Sign Language Content Data
/// Comprehensive collection of signs for learning ISL (Indian Sign Language)

class SignCategory {
  final String name;
  final String hindiName;
  final String icon;
  final List<SignInfo> signs;

  const SignCategory({
    required this.name,
    required this.hindiName,
    required this.icon,
    required this.signs,
  });
}

class SignInfo {
  final String name;
  final String hindiName;
  final String description;
  final String hindiDescription; // Hindi description for accessibility
  final String emoji;
  final String? videoUrl; // For future video tutorials

  const SignInfo({
    required this.name,
    required this.hindiName,
    required this.description,
    this.hindiDescription = '', // Optional - empty for backward compatibility
    required this.emoji,
    this.videoUrl,
  });
}

/// All sign language content organized by category
class SignLanguageContent {
  static const List<SignCategory> categories = [
    // Alphabet
    SignCategory(
      name: "Alphabet",
      hindiName: "वर्णमाला",
      icon: "🔤",
      signs: [
        SignInfo(
            name: "A",
            hindiName: "ए",
            description: "Make a fist with thumb on the side",
            hindiDescription: "मुट्ठी बनाओ, अंगूठा बाहर की तरफ",
            emoji: "🅰️"),
        SignInfo(
            name: "B",
            hindiName: "बी",
            description: "Flat hand, fingers together, thumb tucked in",
            hindiDescription: "सपाट हाथ, उंगलियां साथ, अंगूठा अंदर",
            emoji: "🅱️"),
        SignInfo(
            name: "C",
            hindiName: "सी",
            description: "Curved hand like the letter C",
            hindiDescription: "हाथ को C अक्षर जैसा मोड़ो",
            emoji: "©️"),
        SignInfo(
            name: "D",
            hindiName: "डी",
            description: "Index finger up, other fingers touch thumb",
            hindiDescription: "तर्जनी ऊपर, बाकी उंगलियां अंगूठे को छुएं",
            emoji: "🇩"),
        SignInfo(
            name: "E",
            hindiName: "ई",
            description: "Fingertips touch thumb, curved fingers",
            hindiDescription: "उंगलियों की नोक अंगूठे को छुए, मुड़ी हुई",
            emoji: "🇪"),
        SignInfo(
            name: "F",
            hindiName: "एफ",
            description: "Index and thumb form circle, other fingers up",
            hindiDescription: "तर्जनी और अंगूठे से गोला, बाकी ऊपर",
            emoji: "🇫"),
        SignInfo(
            name: "G",
            hindiName: "जी",
            description: "Index finger pointing sideways, thumb parallel",
            hindiDescription: "तर्जनी बगल में इशारा, अंगूठा समानांतर",
            emoji: "🇬"),
        SignInfo(
            name: "H",
            hindiName: "एच",
            description: "Index and middle finger horizontal",
            hindiDescription: "तर्जनी और मध्यमा क्षैतिज",
            emoji: "🇭"),
        SignInfo(
            name: "I",
            hindiName: "आई",
            description: "Pinky finger up, other fingers in fist",
            hindiDescription: "छोटी उंगली ऊपर, बाकी मुट्ठी में",
            emoji: "🇮"),
        SignInfo(
            name: "J",
            hindiName: "जे",
            description: "Pinky up, draw J shape in air",
            hindiDescription: "छोटी उंगली ऊपर, हवा में J बनाओ",
            emoji: "🇯"),
        SignInfo(
            name: "K",
            hindiName: "के",
            description: "Index and middle finger up in V, thumb between",
            hindiDescription: "V में तर्जनी-मध्यमा, अंगूठा बीच में",
            emoji: "🇰"),
        SignInfo(
            name: "L",
            hindiName: "एल",
            description: "L shape with index finger and thumb",
            hindiDescription: "तर्जनी और अंगूठे से L बनाओ",
            emoji: "🇱"),
        SignInfo(
            name: "M",
            hindiName: "एम",
            description: "Fingers over thumb, three bumps on top",
            hindiDescription: "उंगलियां अंगूठे पर, तीन उभार ऊपर",
            emoji: "🇲"),
        SignInfo(
            name: "N",
            hindiName: "एन",
            description: "Fingers over thumb, two bumps on top",
            hindiDescription: "उंगलियां अंगूठे पर, दो उभार ऊपर",
            emoji: "🇳"),
        SignInfo(
            name: "O",
            hindiName: "ओ",
            description: "Fingers curved to touch thumb, circle shape",
            hindiDescription: "उंगलियां मोड़कर अंगूठे को छुएं, गोल आकार",
            emoji: "🇴"),
        SignInfo(
            name: "P",
            hindiName: "पी",
            description: "Like K but pointing down",
            hindiDescription: "K जैसा पर नीचे की ओर",
            emoji: "🇵"),
        SignInfo(
            name: "Q",
            hindiName: "क्यू",
            description: "Like G but pointing down",
            hindiDescription: "G जैसा पर नीचे की ओर",
            emoji: "🇶"),
        SignInfo(
            name: "R",
            hindiName: "आर",
            description: "Index and middle finger crossed",
            hindiDescription: "तर्जनी और मध्यमा क्रॉस",
            emoji: "🇷"),
        SignInfo(
            name: "S",
            hindiName: "एस",
            description: "Fist with thumb over fingers",
            hindiDescription: "मुट्ठी, अंगूठा उंगलियों के ऊपर",
            emoji: "🇸"),
        SignInfo(
            name: "T",
            hindiName: "टी",
            description: "Fist with thumb between index and middle finger",
            hindiDescription: "मुट्ठी, अंगूठा तर्जनी-मध्यमा के बीच",
            emoji: "🇹"),
        SignInfo(
            name: "U",
            hindiName: "यू",
            description: "Index and middle finger up together",
            hindiDescription: "तर्जनी और मध्यमा साथ ऊपर",
            emoji: "🇺"),
        SignInfo(
            name: "V",
            hindiName: "वी",
            description: "Index and middle finger in V shape",
            hindiDescription: "तर्जनी और मध्यमा V आकार में",
            emoji: "🇻"),
        SignInfo(
            name: "W",
            hindiName: "डब्ल्यू",
            description: "Index, middle, and ring finger up in W",
            hindiDescription: "तर्जनी, मध्यमा, अनामिका W में ऊपर",
            emoji: "🇼"),
        SignInfo(
            name: "X",
            hindiName: "एक्स",
            description: "Index finger hooked",
            hindiDescription: "तर्जनी हुक जैसी मुड़ी",
            emoji: "🇽"),
        SignInfo(
            name: "Y",
            hindiName: "वाई",
            description: "Thumb and pinky extended like Y",
            hindiDescription: "अंगूठा और छोटी उंगली Y जैसे फैली",
            emoji: "🇾"),
        SignInfo(
            name: "Z",
            hindiName: "ज़ेड",
            description: "Index finger draws Z in air",
            hindiDescription: "तर्जनी से हवा में Z बनाओ",
            emoji: "🇿"),
      ],
    ),

    // Numbers
    SignCategory(
      name: "Numbers",
      hindiName: "संख्या",
      icon: "🔢",
      signs: [
        SignInfo(
            name: "0",
            hindiName: "शून्य",
            description: "O shape with fingers and thumb",
            emoji: "0️⃣"),
        SignInfo(
            name: "1",
            hindiName: "एक",
            description: "Index finger pointing up",
            emoji: "1️⃣"),
        SignInfo(
            name: "2",
            hindiName: "दो",
            description: "Index and middle finger up",
            emoji: "2️⃣"),
        SignInfo(
            name: "3",
            hindiName: "तीन",
            description: "Thumb, index, and middle finger up",
            emoji: "3️⃣"),
        SignInfo(
            name: "4",
            hindiName: "चार",
            description: "Four fingers up, thumb tucked",
            emoji: "4️⃣"),
        SignInfo(
            name: "5",
            hindiName: "पांच",
            description: "All five fingers spread open",
            emoji: "5️⃣"),
        SignInfo(
            name: "6",
            hindiName: "छह",
            description: "Thumb contacts pinky, other fingers up",
            emoji: "6️⃣"),
        SignInfo(
            name: "7",
            hindiName: "सात",
            description: "Thumb contacts ring finger, other fingers up",
            emoji: "7️⃣"),
        SignInfo(
            name: "8",
            hindiName: "आठ",
            description: "Thumb contacts middle finger, other fingers up",
            emoji: "8️⃣"),
        SignInfo(
            name: "9",
            hindiName: "नौ",
            description: "Thumb contacts index finger, other fingers up",
            emoji: "9️⃣"),
        SignInfo(
            name: "10",
            hindiName: "दस",
            description: "Shake fist with thumb up (thumbs up motion)",
            emoji: "🔟"),
      ],
    ),

    // Greetings
    SignCategory(
      name: "Greetings",
      hindiName: "अभिवादन",
      icon: "👋",
      signs: [
        SignInfo(
            name: "Hello",
            hindiName: "नमस्ते",
            description: "Both palms together (Namaste) or wave",
            emoji: "🙏"),
        SignInfo(
            name: "Goodbye",
            hindiName: "अलविदा",
            description: "Open palm wave side to side",
            emoji: "👋"),
        SignInfo(
            name: "Good Morning",
            hindiName: "सुप्रभात",
            description: "Sign 'good' + hand rising like sun",
            emoji: "🌅"),
        SignInfo(
            name: "Good Night",
            hindiName: "शुभ रात्रि",
            description: "Sign 'good' + hands together under tilted head",
            emoji: "🌙"),
        SignInfo(
            name: "Thank You",
            hindiName: "धन्यवाद",
            description: "Flat hand from chin forward and down",
            emoji: "🙏"),
        SignInfo(
            name: "Please",
            hindiName: "कृपया",
            description: "Flat hand circles on chest",
            emoji: "🙏"),
        SignInfo(
            name: "Sorry",
            hindiName: "माफ़ी",
            description: "Fist circles on chest",
            emoji: "😔"),
        SignInfo(
            name: "Yes",
            hindiName: "हाँ",
            description: "Nod head or fist moves up and down",
            emoji: "✅"),
        SignInfo(
            name: "No",
            hindiName: "नहीं",
            description: "Shake head or index finger waves side to side",
            emoji: "❌"),
      ],
    ),

    // Common Words
    SignCategory(
      name: "Common Words",
      hindiName: "आम शब्द",
      icon: "💬",
      signs: [
        SignInfo(
            name: "Help",
            hindiName: "मदद",
            description: "Thumbs up on flat palm, lift together",
            emoji: "🆘"),
        SignInfo(
            name: "I",
            hindiName: "मैं",
            description: "Point index finger to chest",
            emoji: "👆"),
        SignInfo(
            name: "You",
            hindiName: "तुम",
            description: "Point index finger forward",
            emoji: "👉"),
        SignInfo(
            name: "Friend",
            hindiName: "दोस्त",
            description: "Hook index fingers together, rotate",
            emoji: "🤝"),
        SignInfo(
            name: "Family",
            hindiName: "परिवार",
            description: "F handshapes circle to touch",
            emoji: "👨‍👩‍👧"),
        SignInfo(
            name: "Love",
            hindiName: "प्यार",
            description: "Cross arms over chest (hug yourself)",
            emoji: "❤️"),
        SignInfo(
            name: "Happy",
            hindiName: "खुश",
            description: "Flat hands brush up chest repeatedly",
            emoji: "😊"),
        SignInfo(
            name: "Sad",
            hindiName: "दुखी",
            description: "Hands move down face slowly",
            emoji: "😢"),
        SignInfo(
            name: "Hungry",
            hindiName: "भूखा",
            description: "C hand moves down chest",
            emoji: "🍽️"),
        SignInfo(
            name: "Thirsty",
            hindiName: "प्यासा",
            description: "Index finger traces line down throat",
            emoji: "💧"),
        SignInfo(
            name: "Tired",
            hindiName: "थका हुआ",
            description: "Bent hands drop on chest",
            emoji: "😫"),
        SignInfo(
            name: "Sick",
            hindiName: "बीमार",
            description: "Middle finger touches forehead and stomach",
            emoji: "🤒"),
      ],
    ),

    // Objects
    SignCategory(
      name: "Objects",
      hindiName: "वस्तुएं",
      icon: "📦",
      signs: [
        SignInfo(
            name: "Phone",
            hindiName: "फ़ोन",
            description: "Fist with pinky and thumb extended, hold to ear",
            emoji: "📱"),
        SignInfo(
            name: "Book",
            hindiName: "किताब",
            description: "Open palms together, then open like pages",
            emoji: "📖"),
        SignInfo(
            name: "Water",
            hindiName: "पानी",
            description: "W shape with three fingers, tap on chin twice",
            emoji: "💧"),
        SignInfo(
            name: "Food",
            hindiName: "खाना",
            description: "Fingertips to mouth, repeated motion",
            emoji: "🍽️"),
        SignInfo(
            name: "House",
            hindiName: "घर",
            description: "Fingertips touch to form roof, hands down for walls",
            emoji: "🏠"),
        SignInfo(
            name: "Car",
            hindiName: "कार",
            description: "Both hands mime steering wheel",
            emoji: "🚗"),
        SignInfo(
            name: "Money",
            hindiName: "पैसा",
            description: "Flat hand taps into cupped hand repeatedly",
            emoji: "💰"),
        SignInfo(
            name: "Computer",
            hindiName: "कंप्यूटर",
            description: "C handshape moves along non-dominant arm",
            emoji: "💻"),
        SignInfo(
            name: "Pen",
            hindiName: "कलम",
            description: "Mime writing motion",
            emoji: "🖊️"),
        SignInfo(
            name: "Key",
            hindiName: "चाबी",
            description: "Twist index and thumb like turning key",
            emoji: "🔑"),
      ],
    ),

    // Common Phrases
    SignCategory(
      name: "Phrases",
      hindiName: "वाक्य",
      icon: "💭",
      signs: [
        SignInfo(
            name: "How are you?",
            hindiName: "कैसे हो?",
            description:
                "Sign 'how' (palms up, fingers bent) + point to person",
            emoji: "🤔"),
        SignInfo(
            name: "I am fine",
            hindiName: "मैं ठीक हूँ",
            description: "Point to self + thumbs up or 'good' sign",
            emoji: "👍"),
        SignInfo(
            name: "What is your name?",
            hindiName: "आपका नाम क्या है?",
            description: "Sign 'what' + 'name' + point to person",
            emoji: "❓"),
        SignInfo(
            name: "My name is...",
            hindiName: "मेरा नाम है...",
            description: "Point to self + sign 'name' + fingerspell name",
            emoji: "👤"),
        SignInfo(
            name: "Nice to meet you",
            hindiName: "आपसे मिलकर अच्छा लगा",
            description: "Sign 'meet' (index fingers approach) + 'good'",
            emoji: "🤝"),
        SignInfo(
            name: "Where is...?",
            hindiName: "कहाँ है...?",
            description: "Index finger shakes side to side (questioning)",
            emoji: "📍"),
        SignInfo(
            name: "I don't understand",
            hindiName: "मुझे समझ नहीं आया",
            description: "Index finger touches forehead + shake head",
            emoji: "🤷"),
        SignInfo(
            name: "Please repeat",
            hindiName: "फिर से बोलिए",
            description: "Hand rotates in circles toward self",
            emoji: "🔄"),
        SignInfo(
            name: "I love you",
            hindiName: "मैं तुमसे प्यार करता हूँ",
            description: "Thumb, index, and pinky extended (ILY sign)",
            emoji: "🤟"),
        SignInfo(
            name: "See you later",
            hindiName: "फिर मिलेंगे",
            description: "Point to eyes + wave",
            emoji: "👀"),
      ],
    ),
  ];

  /// Get total sign count
  static int get totalSigns =>
      categories.fold(0, (sum, cat) => sum + cat.signs.length);

  /// Search for signs by name
  static List<SignInfo> search(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <SignInfo>[];

    for (final category in categories) {
      for (final sign in category.signs) {
        if (sign.name.toLowerCase().contains(lowerQuery) ||
            sign.hindiName.contains(query)) {
          results.add(sign);
        }
      }
    }
    return results;
  }
}
