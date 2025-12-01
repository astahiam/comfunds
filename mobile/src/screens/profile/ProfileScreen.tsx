/**
 * Profile Screen
 * User profile and settings
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../../context/AuthContext';
import Card from '../../components/Card';
import Button from '../../components/Button';
import {Colors, Theme} from '../../constants';

const ProfileScreen: React.FC = () => {
  const {user, logout} = useAuth();

  const handleLogout = () => {
    Alert.alert('Keluar', 'Apakah Anda yakin ingin keluar?', [
      {text: 'Batal', style: 'cancel'},
      {
        text: 'Keluar',
        style: 'destructive',
        onPress: async () => {
          await logout();
        },
      },
    ]);
  };

  const menuItems = [
    {
      icon: 'person',
      label: 'Edit Profil',
      onPress: () => {},
    },
    {
      icon: 'security',
      label: 'Keamanan',
      onPress: () => {},
    },
    {
      icon: 'notifications',
      label: 'Notifikasi',
      onPress: () => {},
    },
    {
      icon: 'help',
      label: 'Bantuan',
      onPress: () => {},
    },
    {
      icon: 'info',
      label: 'Tentang Aplikasi',
      onPress: () => {},
    },
  ];

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.avatarContainer}>
          <View style={styles.avatar}>
            <Icon name="person" size={40} color={Colors.primary} />
          </View>
        </View>
        <Text style={styles.name}>{user?.name || 'Pengguna'}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        {user?.roles && user.roles.length > 0 && (
          <View style={styles.rolesContainer}>
            {user.roles.map((role, index) => (
              <View key={index} style={styles.roleBadge}>
                <Text style={styles.roleText}>{role}</Text>
              </View>
            ))}
          </View>
        )}
      </View>

      <View style={styles.section}>
        <Card>
          {menuItems.map((item, index) => (
            <TouchableOpacity
              key={index}
              style={[
                styles.menuItem,
                index !== menuItems.length - 1 && styles.menuItemBorder,
              ]}
              onPress={item.onPress}>
              <View style={styles.menuItemLeft}>
                <Icon name={item.icon} size={24} color={Colors.textDark} />
                <Text style={styles.menuItemText}>{item.label}</Text>
              </View>
              <Icon name="chevron-right" size={24} color={Colors.textLight} />
            </TouchableOpacity>
          ))}
        </Card>
      </View>

      <View style={styles.section}>
        <Button
          title="Keluar"
          onPress={handleLogout}
          variant="outline"
          style={styles.logoutButton}
        />
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>Hajifund v1.0.0</Text>
        <Text style={styles.footerText}>
          Solusi Terbaik Crowdfunding Berbasis Syariah
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgLight,
  },
  header: {
    backgroundColor: Colors.white,
    padding: Theme.spacing.xl,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.lightGray,
  },
  avatarContainer: {
    marginBottom: Theme.spacing.md,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.primaryLighter,
    justifyContent: 'center',
    alignItems: 'center',
  },
  name: {
    fontSize: Theme.fontSize.xl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  email: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginBottom: Theme.spacing.md,
  },
  rolesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: Theme.spacing.xs,
  },
  roleBadge: {
    paddingVertical: Theme.spacing.xs,
    paddingHorizontal: Theme.spacing.sm,
    borderRadius: Theme.borderRadius.sm,
    backgroundColor: Colors.primaryLighter,
  },
  roleText: {
    fontSize: Theme.fontSize.xs,
    color: Colors.primary,
    fontWeight: Theme.fontWeight.medium,
    textTransform: 'capitalize',
  },
  section: {
    padding: Theme.spacing.md,
  },
  menuItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Theme.spacing.md,
  },
  menuItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.lightGray,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Theme.spacing.md,
  },
  menuItemText: {
    fontSize: Theme.fontSize.md,
    color: Colors.textDark,
  },
  logoutButton: {
    borderColor: Colors.error,
  },
  footer: {
    padding: Theme.spacing.xl,
    alignItems: 'center',
  },
  footerText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textLight,
    textAlign: 'center',
    marginBottom: Theme.spacing.xs,
  },
});

export default ProfileScreen;

