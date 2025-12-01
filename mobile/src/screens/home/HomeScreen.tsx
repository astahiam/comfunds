/**
 * Home Screen
 * Dashboard for authenticated users
 */

import React, {useEffect, useState} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../../context/AuthContext';
import Card from '../../components/Card';
import {Colors, Theme} from '../../constants';
import ApiService from '../../services/ApiService';
import {Project} from '../../types';

const HomeScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const {user} = useAuth();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadProjects();
  }, []);

  const loadProjects = async () => {
    try {
      const response = await ApiService.getProjects({status: 'active', limit: 5});
      if (response.status === 'success' && response.data) {
        setProjects(response.data);
      }
    } catch (error) {
      console.error('Error loading projects:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadProjects();
  };

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }>
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Selamat Datang</Text>
          <Text style={styles.name}>{user?.name || 'Pengguna'}</Text>
        </View>
        <TouchableOpacity onPress={() => navigation.navigate('Profile')}>
          <View style={styles.avatar}>
            <Icon name="person" size={24} color={Colors.primary} />
          </View>
        </TouchableOpacity>
      </View>

      <View style={styles.statsContainer}>
        <Card style={styles.statCard}>
          <Icon name="trending-up" size={24} color={Colors.primary} />
          <Text style={styles.statValue}>Rp 2.5M+</Text>
          <Text style={styles.statLabel}>Total Pendanaan</Text>
        </Card>
        <Card style={styles.statCard}>
          <Icon name="business-center" size={24} color={Colors.primary} />
          <Text style={styles.statValue}>350+</Text>
          <Text style={styles.statLabel}>UMKM Terdanai</Text>
        </Card>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Proyek Terbaru</Text>
          <TouchableOpacity onPress={() => navigation.navigate('Projects')}>
            <Text style={styles.seeAll}>Lihat Semua</Text>
          </TouchableOpacity>
        </View>

        {projects.length === 0 ? (
          <Card>
            <Text style={styles.emptyText}>Belum ada proyek aktif</Text>
          </Card>
        ) : (
          projects.map(project => (
            <Card
              key={project.id}
              style={styles.projectCard}
              onPress={() =>
                navigation.navigate('ProjectDetail', {id: project.id})
              }>
              <Text style={styles.projectTitle}>{project.title}</Text>
              <Text style={styles.projectDescription} numberOfLines={2}>
                {project.description}
              </Text>
              <View style={styles.projectFooter}>
                <View>
                  <Text style={styles.fundingLabel}>Target Pendanaan</Text>
                  <Text style={styles.fundingAmount}>
                    Rp {project.funding_goal.toLocaleString('id-ID')}
                  </Text>
                </View>
                <View style={styles.progressBar}>
                  <View
                    style={[
                      styles.progressFill,
                      {
                        width: `${
                          (project.current_funding / project.funding_goal) * 100
                        }%`,
                      },
                    ]}
                  />
                </View>
              </View>
              </Card>
            </TouchableOpacity>
          ))
        )}
      </View>

      <View style={styles.quickActions}>
        <TouchableOpacity
          style={styles.actionButton}
          onPress={() => navigation.navigate('CreateProject')}>
          <Icon name="add-business" size={24} color={Colors.primary} />
          <Text style={styles.actionText}>Buat Proyek</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.actionButton}
          onPress={() => navigation.navigate('Investments')}>
          <Icon name="trending-up" size={24} color={Colors.primary} />
          <Text style={styles.actionText}>Portfolio</Text>
        </TouchableOpacity>
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Theme.spacing.lg,
    backgroundColor: Colors.white,
    borderBottomWidth: 1,
    borderBottomColor: Colors.lightGray,
  },
  greeting: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
  },
  name: {
    fontSize: Theme.fontSize.xl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginTop: Theme.spacing.xs,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.primaryLighter,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statsContainer: {
    flexDirection: 'row',
    padding: Theme.spacing.md,
    gap: Theme.spacing.md,
  },
  statCard: {
    flex: 1,
    alignItems: 'center',
    padding: Theme.spacing.md,
  },
  statValue: {
    fontSize: Theme.fontSize.xl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginTop: Theme.spacing.sm,
  },
  statLabel: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginTop: Theme.spacing.xs,
  },
  section: {
    padding: Theme.spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Theme.spacing.md,
  },
  sectionTitle: {
    fontSize: Theme.fontSize.lg,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
  },
  seeAll: {
    fontSize: Theme.fontSize.sm,
    color: Colors.primary,
    fontWeight: Theme.fontWeight.semibold,
  },
  projectCard: {
    marginBottom: Theme.spacing.md,
  },
  projectTitle: {
    fontSize: Theme.fontSize.md,
    fontWeight: Theme.fontWeight.semibold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  projectDescription: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginBottom: Theme.spacing.md,
  },
  projectFooter: {
    marginTop: Theme.spacing.md,
  },
  fundingLabel: {
    fontSize: Theme.fontSize.xs,
    color: Colors.textLight,
    marginBottom: Theme.spacing.xs,
  },
  fundingAmount: {
    fontSize: Theme.fontSize.md,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.primary,
  },
  progressBar: {
    height: 4,
    backgroundColor: Colors.lightGray,
    borderRadius: 2,
    marginTop: Theme.spacing.sm,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primary,
  },
  emptyText: {
    textAlign: 'center',
    color: Colors.textMedium,
    padding: Theme.spacing.lg,
  },
  quickActions: {
    flexDirection: 'row',
    padding: Theme.spacing.md,
    gap: Theme.spacing.md,
  },
  actionButton: {
    flex: 1,
    backgroundColor: Colors.white,
    borderRadius: Theme.borderRadius.md,
    padding: Theme.spacing.md,
    alignItems: 'center',
    ...Theme.shadow.small,
  },
  actionText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textDark,
    marginTop: Theme.spacing.xs,
    fontWeight: Theme.fontWeight.medium,
  },
});

export default HomeScreen;

