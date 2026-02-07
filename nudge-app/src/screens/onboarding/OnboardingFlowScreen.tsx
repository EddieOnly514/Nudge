import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, TextInput } from 'react-native';

export default function OnboardingFlowScreen() {
  const [step, setStep] = useState(0);
  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [gender, setGender] = useState('');
  const [bio, setBio] = useState('');

  const handleNext = () => {
    if (step < 3) {
      setStep(step + 1);
    } else {
      // Complete onboarding
      console.log('Onboarding complete');
    }
  };

  const renderStep = () => {
    switch (step) {
      case 0:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.question}>What's your name?</Text>
            <TextInput
              style={styles.input}
              placeholder="Your name"
              value={name}
              onChangeText={setName}
              autoFocus
            />
          </View>
        );
      case 1:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.question}>How old are you?</Text>
            <TextInput
              style={styles.input}
              placeholder="Age"
              keyboardType="number-pad"
              value={age}
              onChangeText={setAge}
              autoFocus
            />
          </View>
        );
      case 2:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.question}>What's your gender?</Text>
            <TouchableOpacity
              style={[styles.optionButton, gender === 'man' && styles.selectedOption]}
              onPress={() => setGender('man')}
            >
              <Text style={styles.optionText}>Man</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.optionButton, gender === 'woman' && styles.selectedOption]}
              onPress={() => setGender('woman')}
            >
              <Text style={styles.optionText}>Woman</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.optionButton, gender === 'non-binary' && styles.selectedOption]}
              onPress={() => setGender('non-binary')}
            >
              <Text style={styles.optionText}>Non-binary</Text>
            </TouchableOpacity>
          </View>
        );
      case 3:
        return (
          <View style={styles.stepContent}>
            <Text style={styles.question}>Tell us about yourself</Text>
            <TextInput
              style={[styles.input, styles.bioInput]}
              placeholder="A little bit about you..."
              multiline
              value={bio}
              onChangeText={setBio}
              autoFocus
            />
          </View>
        );
      default:
        return null;
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <View style={styles.progressBar}>
          {[0, 1, 2, 3].map((i) => (
            <View
              key={i}
              style={[styles.progressDot, i <= step && styles.progressDotActive]}
            />
          ))}
        </View>

        {renderStep()}

        <TouchableOpacity style={styles.button} onPress={handleNext}>
          <Text style={styles.buttonText}>{step < 3 ? 'Next' : 'Finish'}</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF',
  },
  content: {
    flex: 1,
    padding: 24,
  },
  progressBar: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: 48,
  },
  progressDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#DDD',
    marginHorizontal: 4,
  },
  progressDotActive: {
    backgroundColor: '#FF6B9D',
  },
  stepContent: {
    flex: 1,
  },
  question: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 24,
  },
  input: {
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 12,
    padding: 16,
    fontSize: 18,
  },
  bioInput: {
    height: 120,
    textAlignVertical: 'top',
  },
  optionButton: {
    borderWidth: 2,
    borderColor: '#DDD',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  selectedOption: {
    borderColor: '#FF6B9D',
    backgroundColor: '#FFF0F5',
  },
  optionText: {
    fontSize: 18,
    textAlign: 'center',
    color: '#333',
  },
  button: {
    backgroundColor: '#FF6B9D',
    paddingVertical: 16,
    borderRadius: 12,
  },
  buttonText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
});
