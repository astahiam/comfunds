/**
 * Register Screen
 */

import React, {useState} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../../context/AuthContext';
import Button from '../../components/Button';
import Input from '../../components/Input';
import {Colors, Theme} from '../../constants';

const RegisterScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const {register} = useAuth();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    roles: ['member'],
  });
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleRegister = async () => {
    if (!formData.name || !formData.email || !formData.password) {
      Alert.alert('Error', 'Mohon isi semua field yang wajib');
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      Alert.alert('Error', 'Password dan konfirmasi password tidak sama');
      return;
    }

    if (formData.password.length < 8) {
      Alert.alert('Error', 'Password minimal 8 karakter');
      return;
    }

    setLoading(true);
    try {
      const {confirmPassword, ...registerData} = formData;
      await register(registerData);
    } catch (error: any) {
      Alert.alert('Registrasi Gagal', error.message || 'Terjadi kesalahan');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled">
        <View style={styles.header}>
          <Text style={styles.title}>Daftar Akun</Text>
          <Text style={styles.subtitle}>Buat akun baru untuk mulai berinvestasi</Text>
        </View>

        <View style={styles.form}>
          <Input
            label="Nama Lengkap"
            placeholder="Masukkan nama lengkap"
            value={formData.name}
            onChangeText={text => setFormData({...formData, name: text})}
            leftIcon={<Icon name="person" size={20} color={Colors.textLight} />}
          />

          <Input
            label="Email"
            placeholder="Masukkan email"
            value={formData.email}
            onChangeText={text => setFormData({...formData, email: text})}
            keyboardType="email-address"
            autoCapitalize="none"
            leftIcon={<Icon name="email" size={20} color={Colors.textLight} />}
          />

          <Input
            label="Nomor Telepon"
            placeholder="Masukkan nomor telepon"
            value={formData.phone}
            onChangeText={text => setFormData({...formData, phone: text})}
            keyboardType="phone-pad"
            leftIcon={<Icon name="phone" size={20} color={Colors.textLight} />}
          />

          <Input
            label="Password"
            placeholder="Minimal 8 karakter"
            value={formData.password}
            onChangeText={text => setFormData({...formData, password: text})}
            secureTextEntry={!showPassword}
            rightIcon={
              <Icon
                name={showPassword ? 'visibility' : 'visibility-off'}
                size={20}
                color={Colors.textLight}
                onPress={() => setShowPassword(!showPassword)}
              />
            }
          />

          <Input
            label="Konfirmasi Password"
            placeholder="Ulangi password"
            value={formData.confirmPassword}
            onChangeText={text => setFormData({...formData, confirmPassword: text})}
            secureTextEntry={!showPassword}
          />

          <Button
            title="Daftar"
            onPress={handleRegister}
            loading={loading}
            size="large"
            style={styles.registerButton}
          />

          <View style={styles.footer}>
            <Text style={styles.footerText}>Sudah punya akun? </Text>
            <Text
              style={styles.linkText}
              onPress={() => navigation.navigate('Login')}>
              Masuk
            </Text>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.white,
  },
  content: {
    flexGrow: 1,
    padding: Theme.spacing.lg,
  },
  header: {
    marginBottom: Theme.spacing.xl,
    marginTop: Theme.spacing.lg,
  },
  title: {
    fontSize: Theme.fontSize.xxl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  subtitle: {
    fontSize: Theme.fontSize.md,
    color: Colors.textMedium,
  },
  form: {
    width: '100%',
  },
  registerButton: {
    marginTop: Theme.spacing.md,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: Theme.spacing.lg,
  },
  footerText: {
    fontSize: Theme.fontSize.md,
    color: Colors.textMedium,
  },
  linkText: {
    fontSize: Theme.fontSize.md,
    color: Colors.primary,
    fontWeight: Theme.fontWeight.semibold,
  },
});

export default RegisterScreen;

