"use client";

import { motion, AnimatePresence, type Variants } from "framer-motion";

/**
 * Spring configurations optimized for Stripe/Linear-style subtle, professional feel.
 * High damping = minimal overshoot. Lower stiffness = smoother feel.
 */
export const springs = {
  /** Default for most interactions - smooth and professional */
  smooth: { type: "spring", stiffness: 200, damping: 25 } as const,
  /** Quick feedback for buttons and small elements */
  snappy: { type: "spring", stiffness: 400, damping: 35 } as const,
  /** Slow, elegant transitions for page/modal reveals */
  gentle: { type: "spring", stiffness: 100, damping: 20 } as const,
  /** Very responsive, near-instant */
  quick: { type: "spring", stiffness: 500, damping: 40 } as const,
} as const;

/**
 * Easing curves for non-spring animations
 */
export const easings = {
  /** Smooth deceleration (ease-out) */
  out: [0.22, 1, 0.36, 1] as const,
  /** Smooth acceleration (ease-in) */
  in: [0.4, 0, 1, 1] as const,
  /** Smooth both (ease-in-out) */
  inOut: [0.4, 0, 0.2, 1] as const,
} as const;

/**
 * Animation variant presets
 */

/** Fade up from below - great for scroll reveals */
export const fadeUp: Variants = {
  hidden: {
    opacity: 0,
    y: 24,
  },
  visible: {
    opacity: 1,
    y: 0,
    transition: springs.smooth,
  },
  exit: {
    opacity: 0,
    y: -12,
    transition: { duration: 0.2 },
  },
};

/** Fade in with subtle scale */
export const fadeScale: Variants = {
  hidden: {
    opacity: 0,
    scale: 0.96,
  },
  visible: {
    opacity: 1,
    scale: 1,
    transition: springs.smooth,
  },
  exit: {
    opacity: 0,
    scale: 0.98,
    transition: { duration: 0.15 },
  },
};

/** Slide in from left */
export const slideLeft: Variants = {
  hidden: {
    opacity: 0,
    x: -24,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: springs.smooth,
  },
  exit: {
    opacity: 0,
    x: 24,
    transition: { duration: 0.15 },
  },
};

/** Slide in from right */
export const slideRight: Variants = {
  hidden: {
    opacity: 0,
    x: 24,
  },
  visible: {
    opacity: 1,
    x: 0,
    transition: springs.smooth,
  },
  exit: {
    opacity: 0,
    x: -24,
    transition: { duration: 0.15 },
  },
};

/** Container with staggered children - use on parent element */
export const staggerContainer: Variants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.06,
      delayChildren: 0.1,
    },
  },
};

/** Faster stagger for lists */
export const staggerFast: Variants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.04,
      delayChildren: 0.05,
    },
  },
};

/** Slower stagger for hero sections */
export const staggerSlow: Variants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

/**
 * Button/interactive element hover and tap props
 * Use with spread: {...buttonMotion}
 */
export const buttonMotion = {
  whileHover: { scale: 1.02 },
  whileTap: { scale: 0.98 },
  transition: springs.snappy,
} as const;

/** Subtle card hover */
export const cardMotion = {
  whileHover: { y: -4 },
  transition: springs.smooth,
} as const;

/** List item hover */
export const listItemMotion = {
  whileHover: { x: 4 },
  transition: springs.snappy,
} as const;

/**
 * Reduced motion safe wrapper
 * Returns empty object if user prefers reduced motion
 */
export function getMotionProps(
  props: Record<string, unknown>,
  prefersReducedMotion: boolean
): Record<string, unknown> {
  if (prefersReducedMotion) {
    return {};
  }
  return props;
}

/**
 * Type-safe motion component exports
 */
export const MotionDiv = motion.div;
export const MotionSpan = motion.span;
export const MotionSection = motion.section;
export const MotionNav = motion.nav;
export const MotionButton = motion.button;
export const MotionA = motion.a;
export const MotionUl = motion.ul;
export const MotionLi = motion.li;
export const MotionHeader = motion.header;
export const MotionFooter = motion.footer;
export const MotionArticle = motion.article;
export const MotionAside = motion.aside;
export const MotionMain = motion.main;
export const MotionP = motion.p;
export const MotionH1 = motion.h1;
export const MotionH2 = motion.h2;
export const MotionH3 = motion.h3;
export const MotionH4 = motion.h4;

// Re-export essentials from framer-motion
export { motion, AnimatePresence };
export type { Variants };
