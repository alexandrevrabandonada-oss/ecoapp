import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import tsPlugin from "@typescript-eslint/eslint-plugin";
import reactHooks from "eslint-plugin-react-hooks";
import nextPlugin from "@next/eslint-plugin-next";

export default [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      "**/dist/**",
      "**/coverage/**",
      "**/reports/**",
      "tools/_patch_backup/**",
      "tools/**/_patch_backup/**",
      "**/*.bak-*",
      "**/*.bak",
      "**/*.log"
    ],
  },

  // JS base (somente src/)
  {
    ...js.configs.recommended,
    files: ["src/**/*.{js,jsx,ts,tsx}"],
  },

  // TS/TSX + Next + React Hooks (somente src/)
  {
    files: ["src/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        ecmaFeatures: { jsx: true },
      },
    },
    plugins: {
      "@typescript-eslint": tsPlugin,
      "react-hooks": reactHooks,
      "@next/next": nextPlugin,
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,

      // minsafe:
      "no-undef": "off",
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],
      "@typescript-eslint/no-explicit-any": "off",

      // hooks + next:
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",
      "@next/next/no-img-element": "warn",
    },
  },
  // ECO_MINSAFE_OVERRIDES_v0_1
  {
    files: ["src/**/*.{js,jsx,ts,tsx}"],
    linterOptions: { reportUnusedDisableDirectives: "off" },
    rules: {
      "no-empty": "off",
      "no-unsafe-finally": "off"
    }
  },
];
