import Cocoa

public class GridableLayout: FlowLayout {

  public var contentSize = CGSize.zero

  private var layoutAttributes: [NSCollectionViewLayoutAttributes]?

  open override var collectionViewContentSize: CGSize {
    if scrollDirection != .horizontal {
      contentSize.height = super.collectionViewContentSize.height
    }

    return contentSize
  }

  open override func prepare() {
    guard let delegate = collectionView?.delegate as? Delegate,
      let component = delegate.component,
      let layout = component.model.layout
      else {
        return
    }

    super.prepare()

    var layoutAttributes = [NSCollectionViewLayoutAttributes]()

    for index in 0..<(collectionView?.numberOfItems(inSection: 0) ?? 0) {
      if let itemAttribute = self.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) {
        layoutAttributes.append(itemAttribute)
      }
    }

    self.layoutAttributes = layoutAttributes

    switch scrollDirection {
    case .horizontal:
      contentSize.width = 0.0
      contentSize.height = 0.0

      if let firstItem = component.model.items.first {
        contentSize.height = firstItem.size.height * CGFloat(layout.itemsPerRow)

        if component.model.items.count % layout.itemsPerRow == 1 {
          contentSize.width += firstItem.size.width + minimumLineSpacing
        }
      }

      for (index, item) in component.model.items.enumerated() {
        guard layout.itemsPerRow == 1 || index % layout.itemsPerRow == layout.itemsPerRow - 1 else {
          continue
        }

        contentSize.width += item.size.width + minimumInteritemSpacing
      }

      contentSize.height += component.headerHeight
      contentSize.height += component.footerHeight
      contentSize.width -= minimumInteritemSpacing
      contentSize.width += CGFloat(layout.inset.right)
    case .vertical:
      contentSize.width = component.view.frame.width
      contentSize.height = super.collectionViewContentSize.height
      contentSize.height += component.headerHeight
      contentSize.height += component.footerHeight
    }

    contentSize.height += CGFloat(layout.inset.top + layout.inset.bottom)
  }

  public override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
    var attributes = [NSCollectionViewLayoutAttributes]()

    guard let collectionView = collectionView,
      let dataSource = collectionView.dataSource as? DataSource,
      let component = dataSource.component,
      let layout = component.model.layout
      else {
        return attributes
    }

    guard let newAttributes = self.layoutAttributes else {
      return attributes
    }

    var nextX: CGFloat = sectionInset.left
    var nextY: CGFloat = 0.0

    for attribute in newAttributes {
      guard let itemAttribute = attribute.copy() as? NSCollectionViewLayoutAttributes else {
        continue
      }

      guard let indexPath = itemAttribute.indexPath else {
        continue
      }

      itemAttribute.size = component.sizeForItem(at: indexPath)

      if scrollDirection == .horizontal {
        if layout.itemsPerRow > 1 {
          if indexPath.item % Int(layout.itemsPerRow) == 0 {
            itemAttribute.frame.origin.y += sectionInset.top + component.headerHeight
          } else {
            itemAttribute.frame.origin.y = nextY
          }
        } else {
          itemAttribute.frame.origin.y += component.headerHeight
        }

        itemAttribute.frame.origin.x = nextX

        if layout.itemsPerRow == 1 || indexPath.item % layout.itemsPerRow == layout.itemsPerRow - 1 {
          nextX += itemAttribute.size.width + minimumInteritemSpacing
          nextY = 0
        } else {
          nextY = itemAttribute.frame.maxY
        }
      } else {
        itemAttribute.frame.origin.y += component.headerHeight
      }

      attributes.append(itemAttribute)
    }

    return attributes
  }

  public override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
    guard let collectionView = collectionView,
      let delegate = collectionView.delegate as? Delegate,
      let component = delegate.component else {
        return false
    }

    let offset: CGFloat = component.headerHeight + component.footerHeight
    let shouldInvalidateLayout = newBounds.size.height != collectionView.frame.height + offset

    return shouldInvalidateLayout
  }
}
