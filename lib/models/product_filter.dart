enum SortType { relevance, priceLowToHigh, priceHighToLow, newest }

class ProductFilter {
  SortType sortType;
  double? minPrice;
  double? maxPrice;
  bool inStockOnly;

  ProductFilter({
    this.sortType = SortType.relevance,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  void reset() {
    sortType = SortType.relevance;
    minPrice = null;
    maxPrice = null;
    inStockOnly = false;
  }
}
