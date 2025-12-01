/**
 * Card Component
 */

import React from 'react';
import {View, StyleSheet, ViewStyle} from 'react-native';
import {Colors, Theme} from '../constants';

interface CardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  shadow?: boolean;
}

const Card: React.FC<CardProps> = ({children, style, shadow = true}) => {
  return (
    <View
      style={[
        styles.card,
        shadow && Theme.shadow.medium,
        style,
      ]}>
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.white,
    borderRadius: Theme.borderRadius.lg,
    padding: Theme.spacing.md,
    marginBottom: Theme.spacing.md,
  },
});

export default Card;

