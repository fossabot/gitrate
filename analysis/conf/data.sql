INSERT INTO grade_categories (id, category) VALUES
  (DEFAULT, 'Maintainable'),
  (DEFAULT, 'Testable'),
  (DEFAULT, 'Robust'),
  (DEFAULT, 'Secure'),
  (DEFAULT, 'Automated'),
  (DEFAULT, 'Performant');

INSERT INTO github_search_queries (
  id,
  language,
  filename,
  min_repo_size_kib,
  max_repo_size_kib,
  min_stars,
  max_stars,
  pattern,
  enabled
) VALUES (
  DEFAULT,
  'JavaScript',
  '.eslintrc.*',
  10,
  2048,
  0,
  100,
  '',
  TRUE
);

INSERT INTO github_search_queries (
  id,
  language,
  filename,
  min_repo_size_kib,
  max_repo_size_kib,
  min_stars,
  max_stars,
  pattern,
  enabled
) VALUES (
  DEFAULT,
  'JavaScript',
  '.travis.yml',
  10,
  2048,
  0,
  100,
  '',
  TRUE
);

INSERT INTO users (
  id,
  github_user_id,
  github_login,
  full_name,
  developer,
  updated_by_user,
  viewed
) VALUES (
  DEFAULT,
  1,
  'usertest',
  'full name',
  DEFAULT,
  DEFAULT,
  DEFAULT
);

INSERT INTO repositories (
  id,
  raw_id,
  user_id,
  name,
  updated_by_analyzer
) VALUES (
  DEFAULT,
  'asdf',
  (SELECT id FROM users WHERE github_user_id = 1),
  'test_repo',
  DEFAULT
);

INSERT INTO repositories (
  id,
  raw_id,
  user_id,
  name,
  updated_by_analyzer
) VALUES (
  DEFAULT,
  'asdf',
  (SELECT id FROM users WHERE github_user_id = 1),
  'test_repo',
  DEFAULT
) ON CONFLICT (raw_id) DO UPDATE
SET updated_by_analyzer = DEFAULT;

INSERT INTO developers (
  id,
  user_id,
  show_email,
  job_seeker,
  available_for_relocation,
  programming_experience_months,
  work_experience_months,
  description
) VALUES (
  DEFAULT,
  (SELECT id FROM users WHERE github_user_id = 1),
  DEFAULT,
  TRUE,
  DEFAULT,
  DEFAULT,
  DEFAULT,
  DEFAULT
);

INSERT INTO contact_categories (
  id,
  category
) VALUES (
  DEFAULT,
  'Email'
);

INSERT INTO contacts (
  id,
  category_id,
  contact,
  user_id
) VALUES (
  DEFAULT,
  (SELECT id FROM contact_categories WHERE category = 'Email'),
  'mail@domain.com',
  (SELECT id FROM users WHERE github_user_id = 1)
);

INSERT INTO tag_categories (
  id,
  category_rest_id,
  category
) VALUES (
  DEFAULT,
  'languages',
  'Programming Language'
);

INSERT INTO tags (
  id,
  category_id,
  tag,
  keywords,
  weight,
  clicked
) VALUES (
  DEFAULT,
  (SELECT id FROM tag_categories WHERE category_rest_id = 'languages'),
  'JavaScript',
  'js;javascript',
  DEFAULT,
  DEFAULT
);

INSERT INTO tags_users (
  id,
  tag_id,
  user_id
) VALUES (
  DEFAULT,
  (
    SELECT tags.id
    FROM tags
    INNER JOIN tag_categories ON tag_categories.id = tags.category_id
    WHERE tags.tag = 'JavaScript'
  ),
  (SELECT id FROM users WHERE github_user_id = 1)
);

INSERT INTO tags_users_settings (
  id,
  tags_users_id,
  verified
) VALUES (
  DEFAULT,
  1, -- TODO: RETURNING
  TRUE
);

INSERT INTO grades (
  id,
  category_id,
  value,
  repository_id
) VALUES (
  DEFAULT,
  (SELECT id FROM grade_categories WHERE category = 'Maintainable'),
  0.8,
  (SELECT id FROM repositories WHERE raw_id = 'asdf')
) ON CONFLICT (category_id, repository_id) DO UPDATE
SET value = 0.8;

INSERT INTO grades (
  id,
  category_id,
  value,
  repository_id
) VALUES (
  DEFAULT,
  (SELECT id FROM grade_categories WHERE category = 'Maintainable'),
  0.5,
  (SELECT id FROM repositories WHERE raw_id = 'asdf')
) ON CONFLICT (category_id, repository_id) DO UPDATE
SET value = 0.5;

WITH
    maintainable_category AS (SELECT id FROM grade_categories WHERE category = 'Maintainable'),
    testable_category AS (SELECT id FROM grade_categories WHERE category = 'Testable'),
    robust_category AS (SELECT id FROM grade_categories WHERE category = 'Robust'),
    secure_category AS (SELECT id FROM grade_categories WHERE category = 'Secure'),
    performant_category AS (SELECT id FROM grade_categories WHERE category = 'Performant'),
    javascript_tag AS (SELECT id FROM tags WHERE tag = 'JavaScript')
INSERT INTO warnings (id, warning, grade_category_id, tag_id) VALUES (
  DEFAULT,
  'no-mixed-spaces-and-tabs',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'eol-last',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-trailing-spaces',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'semi-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-nested-ternary',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-extra-parens',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unsafe-negation',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unused-vars',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-var',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'array-callback-return',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'class-methods-use-this',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'complexity',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'complexity',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'consistent-return',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'consistent-return',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'curly',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'curly',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'default-case',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'eqeqeq',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'guard-for-in',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-eval',
  (SELECT id FROM secure_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-implied-eval',
  (SELECT id FROM secure_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-extend-native',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-extra-bind',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-labels',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-labels',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-floating-decimal',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-global-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-global-assign',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-implicit-coercion',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-implicit-globals',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-implicit-globals',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-invalid-this',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-lone-blocks',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-loop-func',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-magic-numbers',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-multi-spaces',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new-func',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new-wrappers',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-octal-escape',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-param-reassign',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-return-await',
  (SELECT id FROM performant_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-await-in-loop',
  (SELECT id FROM performant_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-script-url',
  (SELECT id FROM secure_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-self-compare',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-sequences',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unmodified-loop-condition',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unmodified-loop-condition',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unused-expressions',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-call',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-concat',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-escape',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-void',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-with',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-with',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'radix',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'require-await',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'wrap-iife',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'yoda',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'strict',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'init-declarations',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'init-declarations',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-label-var',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-shadow-restricted-names',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-shadow-restricted-names',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-use-before-define',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'global-require',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'handle-callback-err',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-mixed-requires',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new-require',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-path-concat',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-sync',
  (SELECT id FROM performant_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'array-bracket-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'block-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'camelcase',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'comma-dangle',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'comma-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'computed-property-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'func-call-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'func-style',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'id-length',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'key-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'keyword-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'lines-around-directive',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-depth',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-lines',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-nested-callbacks',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-params',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-statements-per-line',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'max-statements',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'new-cap',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'new-parens',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'newline-before-return',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-array-constructor',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-bitwise',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-lonely-if',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-mixed-operators',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-mixed-operators',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-multiple-empty-lines',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-negated-condition',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new-object',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unneeded-ternary',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-whitespace-before-property',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'object-property-newline',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'one-var-declaration-per-line',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'one-var',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'operator-assignment',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'quote-props',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'sort-keys',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'sort-imports',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'space-before-blocks',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'space-in-parens',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'space-infix-ops',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'arrow-body-style',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'arrow-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-duplicate-imports',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-computed-key',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-constructor',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-useless-rename',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'object-shorthand',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-arrow-callback',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-const',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-destructuring',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-rest-params',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-spread',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'prefer-template',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'rest-spread-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'symbol-description',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'template-curly-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'yield-star-spacing',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'valid-jsdoc',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-deletes',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-fors',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-instanceofs',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-nulls',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-switches',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-typeofs',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'better/no-whiles',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-exclusive-tests',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-skipped-tests',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-pending-tests',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/handle-done-callback',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-synchronous-tests',
  (SELECT id FROM performant_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-global-tests',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/valid-test-description',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/valid-suite-description',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-sibling-hooks',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-hooks',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-hooks-for-single-case',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-top-level-hooks',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-identical-title',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/max-top-level-suites',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'mocha/no-nested-tests',
  (SELECT id FROM testable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'private-props/no-unused-or-undeclared',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'private-props/no-use-outside',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/always-return',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/no-return-wrap',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/param-names',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/catch-or-return',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/no-nesting',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/no-callback-in-promise',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'promise/avoid-new',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-compare-neg-zero',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-cond-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-console',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-constant-condition',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-control-regex',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-debugger',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-dupe-args',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-dupe-keys',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-duplicate-case',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-empty',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-empty-character-class',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-ex-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-extra-boolean-cast',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-extra-semi',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-func-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-inner-declarations',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-invalid-regexp',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-irregular-whitespace',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-obj-calls',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-regex-spaces',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-sparse-arrays',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unexpected-multiline',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unreachable',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unsafe-finally',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'use-isnan',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'valid-typeof',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-case-declarations',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-empty-pattern',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-fallthrough',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-octal',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-redeclare',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-self-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-unused-labels',
  (SELECT id FROM maintainable_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-delete-var',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-undef',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'constructor-super',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-class-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-const-assign',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-dupe-class-members',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-new-symbol',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'no-this-before-super',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
), (
  DEFAULT,
  'require-yield',
  (SELECT id FROM robust_category),
  (SELECT id FROM javascript_tag)
);

--SELECT
--  repositories.id,
--  name,
--  updated_by_analyzer,
--  users.github_user_id
--FROM repositories
--INNER JOIN users ON users.id = repositories.user_id;

SELECT * FROM main_page;

-- search page
SELECT
  users.id,
  users.github_login,
  users.full_name,
  developers.available_for_relocation,
  developers.job_seeker,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'technologies'
      AND users_to_tag_details.user_id = users.id
      AND users_to_tag_details.tag IN ('Apache Spark')
    LIMIT 5
  ) AS matched_technologies,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'languages'
      AND users_to_tag_details.user_id = users.id
      AND users_to_tag_details.tag IN ('JavaScript')
    LIMIT 5
  ) AS matched_languages,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'technologies'
      AND users_to_tag_details.user_id = users.id
    LIMIT 5
  ) AS technologies,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'languages'
      AND users_to_tag_details.user_id = users.id
    LIMIT 5
  ) AS languages,
  ARRAY(
    SELECT grade_details
    FROM users_to_grade_details
    WHERE users_to_grade_details.user_id = users.id
  ) AS grades,
  (
    SELECT AVG(users_to_grades.value)
    FROM users_to_grades
    WHERE users_to_grades.user_id = users.id
  ) AS avg_grade,
  (
    SELECT MAX(repositories.updated_by_analyzer)
    FROM repositories
    WHERE user_id = users.id
  ) AS updated_by_analyzer
FROM users
INNER JOIN developers ON developers.user_id = users.id
WHERE users.developer = TRUE
ORDER BY
  avg_grade DESC,
  updated_by_analyzer DESC
LIMIT 20
OFFSET 0;

-- tags autocomplete
SELECT JSON_BUILD_OBJECT('category', tag_categories.category_rest_id, 'tag', tags.tag) as tags
FROM tags
JOIN tag_categories ON tag_categories.id = tags.category_id
WHERE tags.keywords ILIKE '%js%' -- FIXME: index
ORDER BY
 tags.weight DESC,
 tags.clicked DESC
LIMIT 5;

-- user page
SELECT
  users.id,
  users.github_login,
  users.full_name,
  developers.job_seeker,
  developers.available_for_relocation,
  developers.programming_experience_months,
  developers.work_experience_months,
  developers.description,
  ARRAY(
    SELECT JSON_BUILD_OBJECT('category', contact_categories.category, 'contact', contacts.contact)
    FROM contacts
    JOIN contact_categories ON contact_categories.id = contacts.category_id
    WHERE contacts.user_id = users.id
  ) AS contacts,
  GREATEST(users.updated_by_user, (
    SELECT MAX(repositories.updated_by_analyzer)
    FROM repositories
    WHERE user_id = users.id
  )) AS updated,
  ARRAY(
    SELECT grade_details
    FROM users_to_grade_details
    WHERE users_to_grade_details.user_id = users.id
  ) AS grades,
  (
    SELECT AVG(users_to_grades.value)
    FROM users_to_grades
    WHERE users_to_grades.user_id = users.id
  ) AS avg_grade,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'technologies'
      AND users_to_tag_details.user_id = users.id
  ) AS technologies,
  ARRAY(
    SELECT tag_details
    FROM users_to_tag_details
    WHERE
      users_to_tag_details.tag_category = 'languages'
      AND users_to_tag_details.user_id = users.id
  ) AS languages
FROM users
JOIN developers ON developers.user_id = users.id
WHERE users.id = 1
LIMIT 1;

-- delete contact
DELETE FROM contacts
WHERE
  contacts.user_id = 1
  AND contacts.category_id = (SELECT id FROM contact_categories WHERE category = 'Email');