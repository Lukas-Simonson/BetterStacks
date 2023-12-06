//
//  Row.swift
//  BetterStacks
//
//  Created by Lukas Simonson on 12/5/23.
//

import SwiftUI

public struct Row: Layout {
    
    public var arrangement: Arrangement
    
    public init(arrangement: Arrangement) {
        self.arrangement = arrangement
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        cache.sizeItems(for: proposal, with: subviews)
        return CGSize(width: cache.requiredWidth!, height: cache.requiredHeight!)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        cache.sizeItems(for: proposal, with: subviews)
        guard let totalItemWidth = cache.totalItemWidth,
              let itemSizes = cache.itemSizes
        else { fatalError() }
        
        var nextPos = CGPoint(x: bounds.minX, y: bounds.minY)
        let availableSpace = max(bounds.width - totalItemWidth, 0)
        
        switch arrangement {
        case .spacedBy(let spacing):
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += itemSize.width + spacing
            }
        case .spaceBetween:
            let space = availableSpace / CGFloat(subviews.count - 1)
            
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += space + itemSize.width
            }
        case .spaceEvenly:
            let space = availableSpace / CGFloat(subviews.count + 1)
            
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                nextPos.x += space
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += itemSize.width
            }
        case .spaceAround:
            let space = availableSpace / CGFloat(subviews.count * 2)
            
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                nextPos.x += space
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += space + itemSize.width
            }
        case .center:
            let space = availableSpace / 2
            
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                if nextPos == bounds.origin {
                    nextPos.x += space
                }
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += itemSize.width
            }
        case .end:
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                if nextPos == bounds.origin {
                    nextPos.x += availableSpace
                }
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += itemSize.width
            }
        case .start:
            subviews.indices.forEach { index in
                let itemSize = itemSizes[index]
                subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                nextPos.x += itemSize.width
            }
        }
    }
    
    public func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
}

extension Row {
    public struct CacheData {
        var totalItemWidth: CGFloat?
        var itemSizes: [CGSize]?
        var requiredHeight: CGFloat?
        var requiredWidth: CGFloat?
        
        mutating func sizeItems(for proposal: ProposedViewSize, with subviews: Subviews) {
            var idealSizes: [CGSize] = []
            var trueIdealWidth: CGFloat = 0
            
            subviews.forEach { subview in
                let size = subview.sizeThatFits(.unspecified)
                idealSizes.append(size)
                trueIdealWidth += size.width
            }
            
            if let propWidth = proposal.width,
               propWidth < trueIdealWidth {
                print(proposal.width ?? 0, trueIdealWidth)
                handleMinSize(for: proposal, with: subviews)
                return
            }
            
            self.itemSizes = idealSizes
            self.requiredWidth = idealSizes.reduce(into: 0, { $0 += $1.width })
            self.totalItemWidth = self.requiredWidth
            self.requiredHeight = idealSizes.max(by: { $0.height < $1.height })!.height
        }
        
        private mutating func handleMinSize(for proposal: ProposedViewSize, with subviews: Subviews) {
            var minSizes: [CGSize] = []
            var trueMinWidth: CGFloat = 0
            var zeroSizeIndices: [Subviews.Index] = []
            
            subviews.enumerated().forEach { (index, subview) in
                let size = subview.sizeThatFits(.zero)
                minSizes.append(size)
                trueMinWidth += size.width
                if size.width == 0 { zeroSizeIndices.append(index) }
            }
            
            let widthDisparity = (proposal.width ?? 0) - trueMinWidth
            requiredWidth = widthDisparity > 0 ? (proposal.width ?? 0) : trueMinWidth
            
            let zeroItemWidth = widthDisparity / CGFloat(zeroSizeIndices.count)
            let heightProposition = ProposedViewSize(width: zeroItemWidth, height: nil)
            
            requiredHeight = 0
            itemSizes = []
            totalItemWidth = 0
            subviews.indices.forEach { index in
                let prop = zeroSizeIndices.contains(index) ? heightProposition : .zero
                let size = subviews[index].sizeThatFits(prop)
                requiredHeight = max(requiredHeight!, size.height)
                itemSizes!.append(size)
                totalItemWidth! += size.width
            }
        }
    }
}

extension Row {
    public enum Arrangement {
        case spacedBy(CGFloat)
        case spaceBetween
        case spaceEvenly
        case spaceAround
        case center
        case end
        case start
    }
}
