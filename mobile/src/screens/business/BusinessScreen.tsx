/**
 * Business Screen
 * Business management for business owners
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
import {useAuth} from '../../context/AuthContext';
import Card from '../../components/Card';
import Button from '../../components/Button';
import {Colors, Theme} from '../../constants';
import ApiService from '../../services/ApiService';
import {Business} from '../../types';

const BusinessScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const {user} = useAuth();
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadBusinesses();
  }, []);

  const loadBusinesses = async () => {
    try {
      const params: any = {};
      if (user?.roles.includes('business_owner')) {
        params.owner_id = user.id;
      }
      const response = await ApiService.getBusinesses(params);
      if (response.status === 'success' && response.data) {
        setBusinesses(response.data);
      }
    } catch (error) {
      console.error('Error loading businesses:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadBusinesses();
  };

  const renderBusiness = ({item}: {item: Business}) => {
    const getStatusColor = (status: string) => {
      switch (status) {
        case 'approved':
          return Colors.success;
        case 'pending':
          return Colors.warning;
        case 'rejected':
          return Colors.error;
        default:
          return Colors.textMedium;
      }
    };

    return (
      <TouchableOpacity
        onPress={() => navigation.navigate('BusinessDetail', {id: item.id})}>
        <Card style={styles.businessCard}>
        <View style={styles.businessHeader}>
          <View style={styles.businessInfo}>
            <Text style={styles.businessName}>{item.name}</Text>
            <Text style={styles.businessType}>{item.business_type}</Text>
          </View>
          <View
            style={[
              styles.statusBadge,
              {backgroundColor: getStatusColor(item.approval_status) + '20'},
            ]}>
            <Text
              style={[
                styles.statusText,
                {color: getStatusColor(item.approval_status)},
              ]}>
              {item.approval_status}
            </Text>
          </View>
        </View>

        {item.description && (
          <Text style={styles.businessDescription} numberOfLines={2}>
            {item.description}
          </Text>
        )}

        <View style={styles.businessActions}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('BusinessDetail', {id: item.id})}>
            <Icon name="visibility" size={18} color={Colors.primary} />
            <Text style={styles.actionText}>Detail</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('EditBusiness', {id: item.id})}>
            <Icon name="edit" size={18} color={Colors.primary} />
            <Text style={styles.actionText}>Edit</Text>
          </TouchableOpacity>
        </View>
        </Card>
      </TouchableOpacity>
    );
  };

  const canCreateBusiness = user?.roles.includes('business_owner');

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Bisnis Saya</Text>
        {canCreateBusiness && (
          <TouchableOpacity
            onPress={() => navigation.navigate('CreateBusiness')}>
            <Icon name="add" size={24} color={Colors.primary} />
          </TouchableOpacity>
        )}
      </View>

      {canCreateBusiness ? (
        <FlatList
          data={businesses}
          renderItem={renderBusiness}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
          }
          ListEmptyComponent={
            <Card>
              <View style={styles.emptyContainer}>
                <Icon name="store" size={48} color={Colors.textLight} />
                <Text style={styles.emptyText}>
                  Belum ada bisnis yang terdaftar
                </Text>
                <Button
                  title="Buat Bisnis Baru"
                  onPress={() => navigation.navigate('CreateBusiness')}
                  style={styles.createButton}
                />
              </View>
            </Card>
          }
        />
      ) : (
        <Card style={styles.noAccessCard}>
          <Icon name="lock" size={48} color={Colors.textLight} />
          <Text style={styles.noAccessText}>
            Anda tidak memiliki akses untuk mengelola bisnis
          </Text>
          <Text style={styles.noAccessSubtext}>
            Hubungi administrator untuk mendapatkan akses Business Owner
          </Text>
        </Card>
      )}
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
  list: {
    padding: Theme.spacing.md,
  },
  businessCard: {
    marginBottom: Theme.spacing.md,
  },
  businessHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: Theme.spacing.sm,
  },
  businessInfo: {
    flex: 1,
  },
  businessName: {
    fontSize: Theme.fontSize.lg,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  businessType: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    textTransform: 'capitalize',
  },
  statusBadge: {
    paddingVertical: Theme.spacing.xs,
    paddingHorizontal: Theme.spacing.sm,
    borderRadius: Theme.borderRadius.sm,
  },
  statusText: {
    fontSize: Theme.fontSize.xs,
    fontWeight: Theme.fontWeight.medium,
    textTransform: 'capitalize',
  },
  businessDescription: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginBottom: Theme.spacing.md,
  },
  businessActions: {
    flexDirection: 'row',
    gap: Theme.spacing.md,
    marginTop: Theme.spacing.sm,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Theme.spacing.xs,
    paddingVertical: Theme.spacing.xs,
    paddingHorizontal: Theme.spacing.sm,
    borderRadius: Theme.borderRadius.sm,
    backgroundColor: Colors.primaryLighter,
  },
  actionText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.primary,
    fontWeight: Theme.fontWeight.medium,
  },
  emptyContainer: {
    alignItems: 'center',
    padding: Theme.spacing.xl,
  },
  emptyText: {
    fontSize: Theme.fontSize.md,
    color: Colors.textMedium,
    marginTop: Theme.spacing.md,
    marginBottom: Theme.spacing.lg,
    textAlign: 'center',
  },
  createButton: {
    minWidth: 200,
  },
  noAccessCard: {
    margin: Theme.spacing.lg,
    alignItems: 'center',
    padding: Theme.spacing.xl,
  },
  noAccessText: {
    fontSize: Theme.fontSize.md,
    fontWeight: Theme.fontWeight.semibold,
    color: Colors.textDark,
    marginTop: Theme.spacing.md,
    textAlign: 'center',
  },
  noAccessSubtext: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginTop: Theme.spacing.sm,
    textAlign: 'center',
  },
});

export default BusinessScreen;

