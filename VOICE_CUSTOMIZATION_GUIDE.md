# ChorePal Voice Customization Guide

## 🎤 **How to Change the AI Voice**

The AI voice is controlled by the `SpeechBack.swift` file. Here are all the ways to customize it:

## **1. Quick Voice Changes**

### **Change Language/Accent**
In `SpeechBack.swift`, line 15, change the `voiceLanguage`:

```swift
private let voiceLanguage = "en-GB" // Change this to customize voice
```

**Available Options:**
- `"en-US"` - American English (default)
- `"en-GB"` - British English (current)
- `"en-AU"` - Australian English
- `"en-IE"` - Irish English
- `"en-ZA"` - South African English
- `"en-NZ"` - New Zealand English

### **Change Speech Speed**
In `SpeechBack.swift`, line 16, change the `speechRate`:

```swift
private let speechRate: Float = 0.5  // 0.0 (slowest) to 1.0 (fastest)
```

**Recommended Values:**
- `0.3` - Very slow (for children)
- `0.5` - Normal (current)
- `0.7` - Fast
- `1.0` - Very fast

### **Change Voice Pitch**
In `SpeechBack.swift`, line 17, change the `speechPitch`:

```swift
private let speechPitch: Float = 1.0 // 0.5 (lowest) to 2.0 (highest)
```

**Recommended Values:**
- `0.8` - Lower pitch (more masculine)
- `1.0` - Normal pitch (current)
- `1.2` - Higher pitch (more feminine)
- `1.5` - Very high pitch

## **2. Advanced Voice Customization**

### **Different Voice Personalities**

#### **Friendly Assistant (Current)**
```swift
private let voiceLanguage = "en-GB"
private let speechRate: Float = 0.5
private let speechPitch: Float = 1.0
```

#### **Professional Assistant**
```swift
private let voiceLanguage = "en-US"
private let speechRate: Float = 0.6
private let speechPitch: Float = 0.9
```

#### **Energetic Helper**
```swift
private let voiceLanguage = "en-AU"
private let speechRate: Float = 0.7
private let speechPitch: Float = 1.2
```

#### **Calm Guide**
```swift
private let voiceLanguage = "en-GB"
private let speechRate: Float = 0.4
private let speechPitch: Float = 0.8
```

## **3. Runtime Voice Selection**

### **Add Voice Selection to Settings**
You can add a voice selection feature to your app settings:

```swift
// In your settings view
@State private var selectedVoice = "en-GB"

let voices = [
    ("en-US", "American English"),
    ("en-GB", "British English"),
    ("en-AU", "Australian English"),
    ("en-IE", "Irish English")
]

Picker("AI Voice", selection: $selectedVoice) {
    ForEach(voices, id: \.0) { voice in
        Text(voice.1).tag(voice.0)
    }
}
```

### **Update SpeechBack to Use Selected Voice**
```swift
// In SpeechBack.swift
@Published var selectedVoiceLanguage = "en-GB"

func speak(_ text: String, rate: Float? = nil, pitch: Float? = nil) {
    // ... existing code ...
    
    if let voice = AVSpeechSynthesisVoice(language: selectedVoiceLanguage) {
        utterance.voice = voice
    }
}
```

## **4. Voice Testing**

### **Test Different Voices**
1. **Change the voice settings** in `SpeechBack.swift`
2. **Build and run** the app
3. **Test the voice** by creating a task
4. **Listen to the AI response** and adjust as needed

### **Voice Quality Check**
- **Clarity**: Is the voice easy to understand?
- **Speed**: Is it too fast or too slow?
- **Pitch**: Does it sound natural?
- **Accent**: Is the accent appropriate for your users?

## **5. Platform-Specific Voices**

### **iOS Device Voices**
- **iPhone**: Uses built-in iOS voices
- **iPad**: Same voices as iPhone
- **Mac**: Uses macOS voices (may have more options)

### **Voice Availability**
- **en-US**: Always available
- **en-GB**: Usually available
- **en-AU**: May require download
- **en-IE**: May require download

## **6. Troubleshooting**

### **Voice Not Changing**
- **Check language code**: Make sure it's exactly `"en-GB"` (case-sensitive)
- **Restart app**: Voice changes require app restart
- **Check device**: Some voices may not be available on all devices

### **Voice Too Fast/Slow**
- **Adjust rate**: Change `speechRate` value
- **Test different values**: Try 0.3, 0.5, 0.7, 1.0

### **Voice Too High/Low**
- **Adjust pitch**: Change `speechPitch` value
- **Test different values**: Try 0.8, 1.0, 1.2, 1.5

## **7. Recommended Voice Combinations**

### **For Family Use**
```swift
private let voiceLanguage = "en-GB"
private let speechRate: Float = 0.5
private let speechPitch: Float = 1.0
```

### **For Professional Use**
```swift
private let voiceLanguage = "en-US"
private let speechRate: Float = 0.6
private let speechPitch: Float = 0.9
```

### **For Children**
```swift
private let voiceLanguage = "en-GB"
private let speechRate: Float = 0.4
private let speechPitch: Float = 1.1
```

## **8. Quick Changes**

To quickly test different voices, just change these three lines in `SpeechBack.swift`:

```swift
// Line 15: Change accent
private let voiceLanguage = "en-US" // Try: en-GB, en-AU, en-IE

// Line 16: Change speed
private let speechRate: Float = 0.6  // Try: 0.3, 0.5, 0.7, 1.0

// Line 17: Change pitch
private let speechPitch: Float = 1.1 // Try: 0.8, 1.0, 1.2, 1.5
```

Then build and test the voice feature to hear the changes!
