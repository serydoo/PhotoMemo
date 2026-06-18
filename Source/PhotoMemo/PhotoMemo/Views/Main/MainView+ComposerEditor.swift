import SwiftUI

struct MainComposerEntryPanel: View {

    let currentEditingSlotTitle: String

    let currentEditingSlot: MainFieldSlot?

    let focusedField: MainFieldSlot?

    let arrangingComposerSlot: MainFieldSlot?

    let onPresentLiteralComposer: () -> Void

    let onDismissComposerArrangeMode: () -> Void

    let onActivateEditingSlot: (MainFieldSlot) -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                alignment: .center,
                spacing: 10
            ) {

                Label(
                    "当前自定义区域",
                    systemImage: "rectangle.3.group"
                )
                .font(.subheadline.weight(.medium))

                Text(currentEditingSlotTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("添加文字") {
                    onPresentLiteralComposer()
                }
                .buttonStyle(.bordered)
                .disabled(currentEditingSlot == nil)

                Button("退出整理") {
                    onDismissComposerArrangeMode()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .opacity(
                    arrangingComposerSlot == nil
                    ? 0
                    : 1
                )
                .disabled(
                    arrangingComposerSlot == nil
                )
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 8) {

                    ForEach(
                        MainFieldSlot.allCases,
                        id: \.self
                    ) { slot in

                        Button {
                            onActivateEditingSlot(slot)
                        } label: {
                            Text(slot.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(
                                    focusedField == slot
                                        ? .white
                                        : .primary
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(
                                            focusedField == slot
                                                ? MinimalPalette.accent
                                                : Color.gray.opacity(0.1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.composerEntry.dismissed",
                title: "个性化区域说明",
                message: "左上、右上、左下、右下 4 个自定义区域都可以独立编辑。你可以直接点区域本身，也可以先点这里的四区切换条；选中后再点上方 EXIF、智能数据或用户数据，就会插入到当前区域。长按已选中的模块可进入整理状态，并显示删除按钮与拖动排序。"
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismissComposerArrangeMode()
        }
    }
}

struct MainTemplateFieldEditorView<
    Chip: View,
    InsertionHandle: View,
    Scrubber: View,
    InlineEditor: View
>: View {

    let slot: MainFieldSlot

    let items: [TemplateComposerItem]

    let selectedItemID: String?

    let hoveredItemID: String?

    let arrangingComposerSlot: MainFieldSlot?

    let focusedField: MainFieldSlot?

    let shouldShowScrubber: Bool

    let onActivateEditingSlot: () -> Void

    let onTapComposerItem:
        (String, ScrollViewProxy) -> Void

    let onEnterArrangeMode: (String) -> Void

    let onHoverComposerItem: (String, Bool) -> Void

    let onDropComposerItem:
        (String, String, ScrollViewProxy) -> Bool

    let onDropTargetingComposerItem:
        (String, Bool) -> Void

    let onComposerContentWidthChange:
        (CGFloat) -> Void

    let onComposerViewportWidthChange:
        (CGFloat) -> Void

    let onSyncSelectedComposerItem:
        (ScrollViewProxy, [TemplateComposerItem]) -> Void

    let showInsertionHandle:
        (Int, String, [TemplateComposerItem]) -> Bool

    @ViewBuilder
    let chip:
        (
            TemplateComposerItem,
            Bool,
            Bool,
            Bool
        ) -> Chip

    @ViewBuilder
    let insertionHandle:
        (Int, ScrollViewProxy) -> InsertionHandle

    @ViewBuilder
    let scrubber:
        (ScrollViewProxy, [TemplateComposerItem]) -> Scrubber

    @ViewBuilder
    let inlineEditor: () -> InlineEditor

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(slot.title)
                    .font(.headline)

                Spacer()

                if focusedField == slot {

                    Text(
                        arrangingComposerSlot == slot
                        ? "整理中"
                        : "当前区域"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                MinimalPalette
                                .accent.opacity(0.12)
                            )
                    )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                ScrollViewReader { proxy in

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Group {

                            if items.isEmpty {

                                EmptyView()

                            } else {

                                ScrollView(
                                    .horizontal,
                                    showsIndicators: false
                                ) {

                                    HStack(spacing: 10) {

                                        ForEach(
                                            Array(
                                                items.enumerated()
                                            ),
                                            id: \.element.id
                                        ) { index, item in

                                            if arrangingComposerSlot != slot,
                                               showInsertionHandle(
                                                index,
                                                item.id,
                                                items
                                               ) {

                                                insertionHandle(
                                                    index,
                                                    proxy
                                                )
                                            }

                                            chip(
                                                item,
                                                selectedItemID
                                                    == item.id,
                                                hoveredItemID
                                                    == item.id,
                                                arrangingComposerSlot
                                                    == slot
                                            )
                                            .id(item.id)
                                            .onTapGesture {
                                                onTapComposerItem(
                                                    item.id,
                                                    proxy
                                                )
                                            }
                                            .onLongPressGesture(
                                                minimumDuration: 0.4
                                            ) {
                                                onEnterArrangeMode(
                                                    item.id
                                                )
                                            }
                                            .onHover { isHovered in
                                                onHoverComposerItem(
                                                    item.id,
                                                    isHovered
                                                )
                                            }
                                            .dropDestination(
                                                for: String.self
                                            ) { droppedIDs, _ in

                                                guard
                                                    let droppedID =
                                                        droppedIDs.first
                                                else {
                                                    return false
                                                }

                                                return onDropComposerItem(
                                                    droppedID,
                                                    item.id,
                                                    proxy
                                                )
                                            } isTargeted: { isTargeted in
                                                onDropTargetingComposerItem(
                                                    item.id,
                                                    isTargeted
                                                )
                                            }

                                            if arrangingComposerSlot != slot,
                                               showInsertionHandle(
                                                index + 1,
                                                item.id,
                                                items
                                               ) {

                                                insertionHandle(
                                                    index + 1,
                                                    proxy
                                                )
                                            }
                                        }
                                    }
                                    .background(
                                        GeometryReader { geometry in

                                            Color.clear
                                                .onAppear {
                                                    onComposerContentWidthChange(
                                                        geometry
                                                        .size.width
                                                    )
                                                }
                                                .onChange(
                                                    of: geometry.size.width
                                                ) { _, newWidth in
                                                    onComposerContentWidthChange(
                                                        newWidth
                                                    )
                                                }
                                        }
                                    )
                                    .padding(.vertical, 1)
                                }
                                .background(
                                    GeometryReader { geometry in

                                        Color.clear
                                            .onAppear {
                                                onComposerViewportWidthChange(
                                                    geometry
                                                    .size.width
                                                )
                                            }
                                            .onChange(
                                                of: geometry.size.width
                                            ) { _, newWidth in
                                                onComposerViewportWidthChange(
                                                    newWidth
                                                )
                                            }
                                    }
                                )
                                .frame(height: 44)
                                .onAppear {
                                    onSyncSelectedComposerItem(
                                        proxy,
                                        items
                                    )
                                }
                                .onChange(
                                    of: items.map(\.id)
                                ) { _, _ in
                                    onSyncSelectedComposerItem(
                                        proxy,
                                        items
                                    )
                                }
                                .onChange(
                                    of: selectedItemID
                                ) { _, newID in
                                    guard let newID else {
                                        return
                                    }

                                    withAnimation(
                                        .easeInOut(duration: 0.2)
                                    ) {
                                        proxy.scrollTo(
                                            newID,
                                            anchor: .center
                                        )
                                    }
                                }
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        if shouldShowScrubber,
                           !items.isEmpty {

                            scrubber(
                                proxy,
                                items
                            )
                        }

                        inlineEditor()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        Color.gray.opacity(0.08)
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                )
                .onTapGesture {
                    onActivateEditingSlot()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onActivateEditingSlot()
        }
    }
}
