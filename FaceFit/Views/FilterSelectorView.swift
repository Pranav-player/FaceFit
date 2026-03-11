//
//  FilterSelectorView.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import SwiftUI

struct FilterSelectorView: View {
    @Binding var selectedFilter: FilterOption
    let onFilterSelected: (FilterOption) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(FilterOption.allCases) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                                onFilterSelected(filter)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let filter: FilterOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [filter.filterColor, filter.filterColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? filter.filterColor : Color.white.opacity(0.2),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                        .shadow(color: isSelected ? filter.filterColor.opacity(0.4) : .clear, radius: 8)
                    
                    Image(systemName: filter.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(filter.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
    }
}
