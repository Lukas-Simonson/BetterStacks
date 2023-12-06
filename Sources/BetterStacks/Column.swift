//
//  Column.swift
//  Better Stacks
//
//  Created by Lukas Simonson on 12/6/23.
//

import SwiftUI

public struct Column: Layout {
    public var arrangement: Arrangement
    
    public init(arrangement: Arrangement) {
        self.arrangement = arrangement
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        cache.sizeItems(for: proposal, with: subviews)
//        print(proposal)
        return CGSize(width: cache.requiredWidth!, height: cache.requiredHeight!)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        cache.sizeItems(for: proposal, with: subviews)
        guard let totalItemHeight = cache.totalItemHeight,
              let itemSizes = cache.itemSizes
        else { fatalError() }
        
        var nextPos = CGPoint(x: bounds.minX, y: bounds.minY)
        let availableSpace = max(bounds.height - totalItemHeight, 0)
        
        switch arrangement {
            case .spacedBy(let spacing):
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += itemSize.height + spacing
                }
            case .spaceBetween:
                let space = availableSpace / CGFloat(subviews.count - 1)
                
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += space + itemSize.height
                }
            case .spaceEvenly:
                let space = availableSpace / CGFloat(subviews.count + 1)
                
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    nextPos.y += space
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += itemSize.height
                }
            case .spaceAround:
                let space = availableSpace / CGFloat(subviews.count * 2)
                
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    nextPos.y += space
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += space + itemSize.height
                }
            case .center:
                let space = availableSpace / 2
                nextPos.y += space
                
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += itemSize.height
                }
            case .top:
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += itemSize.height
                }
            case .bottom:
                let space = availableSpace
                nextPos.y += space
                
                subviews.indices.forEach { index in
                    let itemSize = itemSizes[index]
                    subviews[index].place(at: nextPos, proposal: ProposedViewSize(itemSize))
                    nextPos.y += itemSize.height
                }
        }
    }
    
    public func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
}

extension Column {
    public struct CacheData {
        var totalItemHeight: CGFloat?
        var itemSizes: [CGSize]?
        var requiredHeight: CGFloat?
        var requiredWidth: CGFloat?
        
        mutating func sizeItems(for proposal: ProposedViewSize, with subviews: Subviews) {
            var idealSizes: [CGSize] = []
            var trueIdealHeight: CGFloat = 0
            
            subviews.forEach { subview in
                let size = subview.sizeThatFits(.unspecified)
                idealSizes.append(size)
                trueIdealHeight += size.height
            }
            
            if let propHeight = proposal.height,
               propHeight < trueIdealHeight {
                handleMinSize(for: proposal, with: subviews)
                return
            }
            
            self.requiredWidth = idealSizes.max(by: { $0.width < $1.width })!.width
            
            if let propWidth = proposal.width,
               propWidth < self.requiredWidth! {
                handleMinSize(for: proposal, with: subviews)
                return
            }
            
            self.itemSizes = idealSizes
            self.requiredWidth = idealSizes.max(by: { $0.width > $1.width })!.width
            self.requiredHeight = idealSizes.reduce(into: 0, { $0 += $1.height })
            self.totalItemHeight = self.requiredHeight
        }
        
        private mutating func handleMinSize(for proposal: ProposedViewSize, with subviews: Subviews) {
            var minSizes: [CGSize] = []
            var trueMinHeight: CGFloat = 0
            var zeroSizeIndices: [Subviews.Index] = []
            
            subviews.enumerated().forEach { (index, subview) in
                let size = subview.sizeThatFits(.zero)
                minSizes.append(size)
                trueMinHeight += size.height
                if size.height == 0 { zeroSizeIndices.append(index) }
            }
            
            let heightDisparity = (proposal.height ?? 0) - trueMinHeight
            requiredHeight = heightDisparity > 0 ? (proposal.height ?? 0) : trueMinHeight
            
            let zeroItemHeight = heightDisparity / CGFloat(zeroSizeIndices.count)
            let widthProposition = ProposedViewSize(width: proposal.width, height: zeroItemHeight)
            
            requiredWidth = 0
            itemSizes = []
            totalItemHeight = 0
            subviews.indices.forEach { index in
                let prop = zeroSizeIndices.contains(index) ? widthProposition : .zero
                let size = subviews[index].sizeThatFits(prop)
                requiredWidth = max(requiredWidth!, size.width)
                itemSizes!.append(size)
                totalItemHeight! += size.height
            }
        }
    }
}

extension Column {
    public enum Arrangement {
        case spacedBy(CGFloat)
        case spaceBetween
        case spaceEvenly
        case spaceAround
        case center
        case top
        case bottom
    }
}
