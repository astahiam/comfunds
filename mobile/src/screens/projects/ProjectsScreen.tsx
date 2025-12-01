/**
 * Projects Screen
 * List of all available projects
 */

import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import Card from '../../components/Card';
import {Colors, Theme} from '../../constants';
import ApiService from '../../services/ApiService';
import {Project} from '../../types';

const ProjectsScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'active' | 'funded'>('all');

  useEffect(() => {
    loadProjects();
  }, [filter]);

  const loadProjects = async () => {
    try {
      const params: any = {};
      if (filter !== 'all') {
        params.status = filter === 'active' ? 'active' : 'funded';
      }
      const response = await ApiService.getProjects(params);
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

  const renderProject = ({item}: {item: Project}) => {
    const progress = (item.current_funding / item.funding_goal) * 100;

    return (
      <TouchableOpacity
        onPress={() => navigation.navigate('ProjectDetail', {id: item.id})}>
        <Card style={styles.projectCard}>
        <Text style={styles.projectTitle}>{item.title}</Text>
        <Text style={styles.projectDescription} numberOfLines={2}>
          {item.description}
        </Text>

        <View style={styles.fundingInfo}>
          <View style={styles.fundingItem}>
            <Text style={styles.fundingLabel}>Target</Text>
            <Text style={styles.fundingValue}>
              Rp {item.funding_goal.toLocaleString('id-ID')}
            </Text>
          </View>
          <View style={styles.fundingItem}>
            <Text style={styles.fundingLabel}>Terkumpul</Text>
            <Text style={styles.fundingValue}>
              Rp {item.current_funding.toLocaleString('id-ID')}
            </Text>
          </View>
        </View>

        <View style={styles.progressContainer}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, {width: `${progress}%`}]} />
          </View>
          <Text style={styles.progressText}>{progress.toFixed(0)}%</Text>
        </View>

        <View style={styles.projectFooter}>
          <View style={styles.statusBadge}>
            <Text style={styles.statusText}>{item.status}</Text>
          </View>
          <TouchableOpacity
            style={styles.investButton}
            onPress={() =>
              navigation.navigate('Invest', {projectId: item.id})
            }>
            <Text style={styles.investButtonText}>Investasi</Text>
          </TouchableOpacity>
        </View>
      </Card>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Proyek Pendanaan</Text>
        <TouchableOpacity onPress={() => navigation.navigate('CreateProject')}>
          <Icon name="add" size={24} color={Colors.primary} />
        </TouchableOpacity>
      </View>

      <View style={styles.filters}>
        <TouchableOpacity
          style={[styles.filterButton, filter === 'all' && styles.filterActive]}
          onPress={() => setFilter('all')}>
          <Text
            style={[
              styles.filterText,
              filter === 'all' && styles.filterTextActive,
            ]}>
            Semua
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.filterButton,
            filter === 'active' && styles.filterActive,
          ]}
          onPress={() => setFilter('active')}>
          <Text
            style={[
              styles.filterText,
              filter === 'active' && styles.filterTextActive,
            ]}>
            Aktif
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.filterButton,
            filter === 'funded' && styles.filterActive,
          ]}
          onPress={() => setFilter('funded')}>
          <Text
            style={[
              styles.filterText,
              filter === 'funded' && styles.filterTextActive,
            ]}>
            Terdanai
          </Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={projects}
        renderItem={renderProject}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <Card>
            <Text style={styles.emptyText}>Tidak ada proyek ditemukan</Text>
          </Card>
        }
      />
    </View>
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
  title: {
    fontSize: Theme.fontSize.xl,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
  },
  filters: {
    flexDirection: 'row',
    padding: Theme.spacing.md,
    gap: Theme.spacing.sm,
  },
  filterButton: {
    paddingVertical: Theme.spacing.sm,
    paddingHorizontal: Theme.spacing.md,
    borderRadius: Theme.borderRadius.md,
    backgroundColor: Colors.white,
    borderWidth: 1,
    borderColor: Colors.lightGray,
  },
  filterActive: {
    backgroundColor: Colors.primaryLighter,
    borderColor: Colors.primary,
  },
  filterText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
  },
  filterTextActive: {
    color: Colors.primary,
    fontWeight: Theme.fontWeight.semibold,
  },
  list: {
    padding: Theme.spacing.md,
  },
  projectCard: {
    marginBottom: Theme.spacing.md,
  },
  projectTitle: {
    fontSize: Theme.fontSize.lg,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  projectDescription: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginBottom: Theme.spacing.md,
  },
  fundingInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: Theme.spacing.md,
  },
  fundingItem: {
    flex: 1,
  },
  fundingLabel: {
    fontSize: Theme.fontSize.xs,
    color: Colors.textLight,
    marginBottom: Theme.spacing.xs,
  },
  fundingValue: {
    fontSize: Theme.fontSize.md,
    fontWeight: Theme.fontWeight.semibold,
    color: Colors.textDark,
  },
  progressContainer: {
    marginBottom: Theme.spacing.md,
  },
  progressBar: {
    height: 6,
    backgroundColor: Colors.lightGray,
    borderRadius: 3,
    overflow: 'hidden',
    marginBottom: Theme.spacing.xs,
  },
  progressFill: {
    height: '100%',
    backgroundColor: Colors.primary,
  },
  progressText: {
    fontSize: Theme.fontSize.xs,
    color: Colors.textMedium,
    textAlign: 'right',
  },
  projectFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statusBadge: {
    paddingVertical: Theme.spacing.xs,
    paddingHorizontal: Theme.spacing.sm,
    borderRadius: Theme.borderRadius.sm,
    backgroundColor: Colors.primaryLighter,
  },
  statusText: {
    fontSize: Theme.fontSize.xs,
    color: Colors.primary,
    fontWeight: Theme.fontWeight.medium,
    textTransform: 'capitalize',
  },
  investButton: {
    paddingVertical: Theme.spacing.sm,
    paddingHorizontal: Theme.spacing.md,
    borderRadius: Theme.borderRadius.md,
    backgroundColor: Colors.primary,
  },
  investButtonText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.white,
    fontWeight: Theme.fontWeight.semibold,
  },
  emptyText: {
    textAlign: 'center',
    color: Colors.textMedium,
    padding: Theme.spacing.xl,
  },
});

export default ProjectsScreen;

