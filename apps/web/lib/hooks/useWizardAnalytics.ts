'use client';

import { useEffect, useRef, useCallback } from 'react';
import {
  WizardStep,
  trackWizardStep,
  trackWizardStepComplete,
  trackWizardAbandonment,
  trackConversion,
} from '@/lib/analytics';

interface UseWizardAnalyticsOptions {
  step: WizardStep;
  stepNumber: number;
  totalSteps?: number;
}

/**
 * Hook for tracking wizard step analytics
 * Automatically tracks step views, time spent, and provides helpers for completion/abandonment
 */
export function useWizardAnalytics({
  step,
  stepNumber,
  totalSteps = 10,
}: UseWizardAnalyticsOptions) {
  const startTime = useRef<number>(Date.now());
  const hasTrackedView = useRef<boolean>(false);

  // Track step view on mount
  useEffect(() => {
    if (hasTrackedView.current) return;
    hasTrackedView.current = true;

    startTime.current = Date.now();

    trackWizardStep(step, stepNumber, {
      total_steps: totalSteps,
      progress_percentage: Math.round((stepNumber / totalSteps) * 100),
    });

    // Track wizard start conversion on first step
    if (stepNumber === 1) {
      trackConversion('wizard_start');
    }
  }, [step, stepNumber, totalSteps]);

  // Calculate time spent
  const getTimeSpent = useCallback((): number => {
    return Math.floor((Date.now() - startTime.current) / 1000);
  }, []);

  // Track step completion
  const markComplete = useCallback(() => {
    trackWizardStepComplete(step, stepNumber, getTimeSpent());
  }, [step, stepNumber, getTimeSpent]);

  // Track abandonment
  const markAbandoned = useCallback((reason?: string) => {
    trackWizardAbandonment(step, stepNumber, reason);
  }, [step, stepNumber]);

  // Track abandonment on unmount if not completed
  useEffect(() => {
    let completed = false;

    return () => {
      // Only track if the component is being unmounted without completing
      // We don't auto-track here because navigating to next step would trigger this
      if (!completed) {
        // Could add logic here for detecting true abandonment
      }
    };
  }, []);

  return {
    getTimeSpent,
    markComplete,
    markAbandoned,
    startTime: startTime.current,
  };
}

export default useWizardAnalytics;
