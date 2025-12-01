/**
 * Welcome Screen
 * Landing screen for unauthenticated users
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  ScrollView,
  StatusBar,
} from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import {useNavigation} from '@react-navigation/native';
import Button from '../../components/Button';
import {Colors, Theme} from '../../constants';
import {Config} from '../../constants/Config';

const WelcomeScreen: React.FC = () => {
  const navigation = useNavigation<any>();

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.primary} />
      <LinearGradient
        colors={[Colors.primary, Colors.primaryDark]}
        style={styles.gradient}>
        <View style={styles.header}>
          <View style={styles.logoContainer}>
            <Text style={styles.logoIcon}>🕋</Text>
          </View>
          <Text style={styles.title}>Hajifund</Text>
          <Text style={styles.subtitle}>
            {Config.APP_DESCRIPTION}
          </Text>
        </View>

        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>1.2K+</Text>
            <Text style={styles.statLabel}>Investor Aktif</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>350+</Text>
            <Text style={styles.statLabel}>UMKM Terdanai</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>Rp 2.5M+</Text>
            <Text style={styles.statLabel}>Total Pendanaan</Text>
          </View>
        </View>
      </LinearGradient>

      <View style={styles.footer}>
        <Button
          title="Masuk"
          onPress={() => navigation.navigate('Login')}
          size="large"
          style={styles.button}
        />
        <Button
          title="Daftar"
          onPress={() => navigation.navigate('Register')}
          variant="outline"
          size="large"
          style={styles.button}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.white,
  },
  content: {
    flexGrow: 1,
  },
  gradient: {
    flex: 1,
    paddingTop: 60,
    paddingBottom: 40,
    paddingHorizontal: Theme.spacing.lg,
  },
  header: {
    alignItems: 'center',
    marginBottom: Theme.spacing.xxl,
  },
  logoContainer: {
    width: 80,
    height: 80,
    borderRadius: Theme.borderRadius.lg,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Theme.spacing.md,
  },
  logoIcon: {
    fontSize: 40,
  },
  title: {
    fontSize: Theme.fontSize.xxxl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.white,
    marginBottom: Theme.spacing.sm,
    fontFamily: Theme.fontFamily.heading,
  },
  subtitle: {
    fontSize: Theme.fontSize.md,
    color: Colors.white,
    textAlign: 'center',
    opacity: 0.9,
    paddingHorizontal: Theme.spacing.lg,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: Theme.spacing.xl,
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: Theme.fontSize.xxl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.white,
    marginBottom: Theme.spacing.xs,
  },
  statLabel: {
    fontSize: Theme.fontSize.sm,
    color: Colors.white,
    opacity: 0.9,
  },
  footer: {
    padding: Theme.spacing.lg,
    backgroundColor: Colors.white,
  },
  button: {
    marginBottom: Theme.spacing.md,
  },
});

export default WelcomeScreen;

