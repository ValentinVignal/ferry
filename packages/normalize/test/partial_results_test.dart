import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

void main() {
  test('Return partial data', () {
    final data = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
      },
    };

    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    final response = {
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
        }
      ]
    };
    expect(
      denormalizeOperation(
        document: query,
        read: (dataId) => data[dataId],
        addTypename: true,
        returnPartialData: true,
      ),
      equals(response),
    );
  });

  test("Don't return partial data", () {
    final data = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
      },
    };

    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    expect(
      denormalizeOperation(
        document: query,
        read: (dataId) => data[dataId],
        addTypename: true,
        returnPartialData: false,
      ),
      equals(null),
    );
  });

  test('Explicit null', () {
    final data = {
      'Query': {
        '__typename': 'Query',
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        'title': null,
        '__typename': 'Post',
      },
    };
    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    final response = {
      '__typename': 'Query',
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'title': null,
        }
      ]
    };
    expect(
      denormalizeOperation(
        document: query,
        read: (dataId) => data[dataId],
        addTypename: true,
        returnPartialData: false,
      ),
      equals(response),
    );
  });

  group(
      'does not count missing data due to skip/include directives as partial data',
      () {
    test('respects skip directives with literal true', () {
      final query = parseString('''
      query TestQuery {
        posts {
          id
          title @skip(if: true)
        }
      }
    ''');

      final data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
        ),
        equals({
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with literal false', () {
      final query = parseString('''
      query TestQuery {
        posts {
          id
          title @skip(if: false)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello',
            }
          ]
        }),
      );
    });

    test('respects include directives with literal true', () {
      final query = parseString('''
      query TestQuery {
        posts {
          id
          title @include(if: true)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'title': 'Hello World',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello World',
            }
          ]
        }),
      );
    });

    test('respects include directives with literal false', () {
      final query = parseString('''
      query TestQuery {
        posts {
          id
          title @include(if: false)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with variable true', () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          title @skip(if: \$skip)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'skip': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with variable false', () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          title @skip(if: \$skip)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'skip': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello',
            }
          ]
        }),
      );
    });

    test('respects include directives with variable true', () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          title @include(if: \$include)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'title': 'Hello World',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello World',
            }
          ]
        }),
      );
    });

    test('respects include directives with variable false', () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          title @include(if: \$include)
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with value true on fragments', () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          ...PostTitle @skip(if: \$skip)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'skip': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with value false on fragments', () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          ...PostTitle @skip(if: \$skip)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: {
            'skip': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello',
            }
          ]
        }),
      );
    });

    test(
        'throws when skip directives with value false on fragments is used but data is missing',
        () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        onePost {
          id
          ...PostTitle @skip(if: \$skip)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'onePost': {'\$ref': 'Post:123'},
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        () => denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          handleException: false,
          variables: const {
            'skip': false,
          },
        ),
        throwsA(isA<PartialDataException>()),
      );
    });

    test(
        'does not throw inside a list when skip directives with value false on fragments is used but data is missing and allow dangling reference is true',
        () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          ...PostTitle @skip(if: \$skip)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          handleException: false,
          variables: const {
            'skip': false,
          },
          allowDanglingReference: true,
        ),
        const {'__typename': 'Query', 'posts': []},
      );
    });

    test('respects include directives with value true on fragments', () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          ...PostTitle @include(if: \$include)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello World',
          '__typename': 'Post',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello World',
            }
          ]
        }),
      );
    });

    test(
        'respects include directives with value false on fragments, returns null on missing data',
        () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          ...PostTitle @include(if: \$include)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'title': 'hello',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects include directives with value false on fragments', () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          ...PostTitle @include(if: \$include)
        }
      }

      fragment PostTitle on Post {
        title
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with variable true on inline fragments', () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          ... on Post @skip(if: \$skip) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'skip': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test('respects skip directives with variable false on inline fragments',
        () {
      final query = parseString('''
      query TestQuery(\$skip: Boolean!) {
        posts {
          id
          ... @skip(if: \$skip) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello World',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'skip': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello World',
            }
          ]
        }),
      );
    });

    test('respects include directives with variable true on inline fragments',
        () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          ... on Post @include(if: \$include) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello World',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
              'title': 'Hello World',
            }
          ]
        }),
      );
    });

    test('respects include directives with variable false on inline fragments',
        () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          ... on Post @include(if: \$include) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          variables: const {
            'include': false,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });

    test(
        'throws, when a field is specified twice, once in an skipped context and once without and data is missing',
        () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          title
          ... on Post @include(if: \$include) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'onePost': {'\$ref': 'Post:123'},
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
      };

      expect(
        () => denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          handleException: false,
          variables: const {
            'include': false,
          },
        ),
        throwsA(isA<PartialDataException>()),
      );
    });

    test(
        'works when a field once specified twice, once in an skipped context and once without and data is there',
        () {
      final query = parseString('''
      query TestQuery(\$include: Boolean!) {
        posts {
          id
          title
          ... @include(if: \$include) {
            title
          }
        }
      }
    ''');

      const data = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          'title': 'Hello World',
          '__typename': 'Post',
        },
      };

      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) => data[dataId],
          addTypename: true,
          returnPartialData: false,
          handleException: false,
          variables: const {
            'include': true,
          },
        ),
        equals(const {
          '__typename': 'Query',
          'posts': [
            {
              'id': '123',
              'title': 'Hello World',
              '__typename': 'Post',
            }
          ]
        }),
      );
    });
  });
}
