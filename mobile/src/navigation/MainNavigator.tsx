/**
 * Main Navigator
 * Bottom tab navigation for authenticated users
 */

import React from 'react';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {Colors} from '../constants/Colors';
import HomeScreen from '../screens/home/HomeScreen';
import ProjectsScreen from '../screens/projects/ProjectsScreen';
import InvestmentsScreen from '../screens/investments/InvestmentsScreen';
import ProfileScreen from '../screens/profile/ProfileScreen';
import BusinessScreen from '../screens/business/BusinessScreen';

const Tab = createBottomTabNavigator();

const MainNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textLight,
        tabBarStyle: {
          backgroundColor: Colors.white,
          borderTopColor: Colors.lightGray,
          borderTopWidth: 1,
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
        },
      }}>
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          tabBarIcon: ({color, size}) => (
            <Icon name="home" size={size} color={color} />
          ),
          tabBarLabel: 'Beranda',
        }}
      />
      <Tab.Screen
        name="Projects"
        component={ProjectsScreen}
        options={{
          tabBarIcon: ({color, size}) => (
            <Icon name="business-center" size={size} color={color} />
          ),
          tabBarLabel: 'Proyek',
        }}
      />
      <Tab.Screen
        name="Business"
        component={BusinessScreen}
        options={{
          tabBarIcon: ({color, size}) => (
            <Icon name="store" size={size} color={color} />
          ),
          tabBarLabel: 'Bisnis',
        }}
      />
      <Tab.Screen
        name="Investments"
        component={InvestmentsScreen}
        options={{
          tabBarIcon: ({color, size}) => (
            <Icon name="trending-up" size={size} color={color} />
          ),
          tabBarLabel: 'Investasi',
        }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          tabBarIcon: ({color, size}) => (
            <Icon name="person" size={size} color={color} />
          ),
          tabBarLabel: 'Profil',
        }}
      />
    </Tab.Navigator>
  );
};

export default MainNavigator;

