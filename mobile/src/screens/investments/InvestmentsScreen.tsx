/**
 * Investments Screen
 * Investment portfolio and history
 */

import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  RefreshControl,
} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../../context/AuthContext';
import Card from '../../components/Card';
import {Colors, Theme} from '../../constants';
import ApiService from '../../services/ApiService';
import {Investment} from '../../types';

const InvestmentsScreen: React.FC = () => {
  const navigation = useNavigation<any>();
  const {user} = useAuth();
  const [investments, setInvestments] = useState<Investment[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [totalInvested, setTotalInvested] = useState(0);

  useEffect(() => {
    if (user) {
      loadInvestments();
    }
  }, [user]);

  const loadInvestments = async () => {
    if (!user) return;

    try {
      const response = await ApiService.getInvestorPortfolio(user.id);
      if (response.status === 'success' && response.data) {
        setInvestments(response.data);
        const total = response.data.reduce(
          (sum: number, inv: Investment) => sum + inv.amount,
          0,
        );
        setTotalInvested(total);
      }
    } catch (error) {
      console.error('Error loading investments:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadInvestments();
  };

  const renderInvestment = ({item}: {item: Investment}) => {
    const getStatusColor = (status: string) => {
      switch (status) {
        case 'confirmed':
          return Colors.success;
        case 'pending':
          return Colors.warning;
        case 'refunded':
          return Colors.error;
        default:
          return Colors.textMedium;
      }
    };

    return (
      <TouchableOpacity
        onPress={() =>
          navigation.navigate('InvestmentDetail', {id: item.id})
        }>
        <Card style={styles.investmentCard}>
        <View style={styles.investmentHeader}>
          <View style={styles.investmentInfo}>
            <Text style={styles.investmentAmount}>
              Rp {item.amount.toLocaleString('id-ID')}
            </Text>
            <Text style={styles.investmentDate}>
              {new Date(item.investment_date).toLocaleDateString('id-ID')}
            </Text>
          </View>
          <View
            style={[
              styles.statusBadge,
              {backgroundColor: getStatusColor(item.status) + '20'},
            ]}>
            <Text
              style={[
                styles.statusText,
                {color: getStatusColor(item.status)},
              ]}>
              {item.status}
            </Text>
          </View>
        </View>

        {item.profit_sharing_percentage && (
          <View style={styles.profitInfo}>
            <Icon name="trending-up" size={16} color={Colors.success} />
            <Text style={styles.profitText}>
              Profit Sharing: {item.profit_sharing_percentage}%
            </Text>
          </View>
        )}

        {item.transaction_ref && (
          <Text style={styles.transactionRef}>
            Ref: {item.transaction_ref}
          </Text>
        )}
        </Card>
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Portfolio Investasi</Text>
      </View>

      <View style={styles.summaryCard}>
        <View style={styles.summaryItem}>
          <Icon name="account-balance-wallet" size={24} color={Colors.primary} />
          <Text style={styles.summaryLabel}>Total Investasi</Text>
          <Text style={styles.summaryValue}>
            Rp {totalInvested.toLocaleString('id-ID')}
          </Text>
        </View>
        <View style={styles.summaryItem}>
          <Icon name="list" size={24} color={Colors.primary} />
          <Text style={styles.summaryLabel}>Jumlah Investasi</Text>
          <Text style={styles.summaryValue}>{investments.length}</Text>
        </View>
      </View>

      <FlatList
        data={investments}
        renderItem={renderInvestment}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <Card>
            <View style={styles.emptyContainer}>
              <Icon name="trending-up" size={48} color={Colors.textLight} />
              <Text style={styles.emptyText}>
                Belum ada investasi
              </Text>
              <Text style={styles.emptySubtext}>
                Mulai berinvestasi di proyek-proyek yang tersedia
              </Text>
            </View>
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
  summaryCard: {
    flexDirection: 'row',
    padding: Theme.spacing.md,
    gap: Theme.spacing.md,
  },
  summaryItem: {
    flex: 1,
    backgroundColor: Colors.white,
    borderRadius: Theme.borderRadius.md,
    padding: Theme.spacing.md,
    alignItems: 'center',
    ...Theme.shadow.small,
  },
  summaryLabel: {
    fontSize: Theme.fontSize.xs,
    color: Colors.textMedium,
    marginTop: Theme.spacing.xs,
  },
  summaryValue: {
    fontSize: Theme.fontSize.lg,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginTop: Theme.spacing.xs,
  },
  list: {
    padding: Theme.spacing.md,
  },
  investmentCard: {
    marginBottom: Theme.spacing.md,
  },
  investmentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: Theme.spacing.sm,
  },
  investmentInfo: {
    flex: 1,
  },
  investmentAmount: {
    fontSize: Theme.fontSize.lg,
    fontWeight: Theme.fontWeight.bold,
    color: Colors.textDark,
    marginBottom: Theme.spacing.xs,
  },
  investmentDate: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
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
  profitInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Theme.spacing.xs,
    marginTop: Theme.spacing.sm,
  },
  profitText: {
    fontSize: Theme.fontSize.sm,
    color: Colors.success,
    fontWeight: Theme.fontWeight.medium,
  },
  transactionRef: {
    fontSize: Theme.fontSize.xs,
    color: Colors.textLight,
    marginTop: Theme.spacing.xs,
  },
  emptyContainer: {
    alignItems: 'center',
    padding: Theme.spacing.xl,
  },
  emptyText: {
    fontSize: Theme.fontSize.md,
    fontWeight: Theme.fontWeight.semibold,
    color: Colors.textDark,
    marginTop: Theme.spacing.md,
  },
  emptySubtext: {
    fontSize: Theme.fontSize.sm,
    color: Colors.textMedium,
    marginTop: Theme.spacing.sm,
    textAlign: 'center',
  },
});

export default InvestmentsScreen;

