String getTrendingProductsQuery = '''
  query GetAllPosts {
    posts(first: 10) {
      edges {
        node {
          id
          title
          date
        }
      }
    }
  }
''';
