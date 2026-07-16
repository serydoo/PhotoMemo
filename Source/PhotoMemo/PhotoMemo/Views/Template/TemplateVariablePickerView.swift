//
//  TemplateVariablePickerView.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
//


import SwiftUI

struct TemplateVariablePickerView: View {

    let onSelect: (TemplateVariable) -> Void

    var body: some View {

        List {

            Section("识别数据") {

                ForEach(
                    TemplateVariableLibrary.recognized
                ) { variable in

                    variableButton(
                        variable
                    )
                }
            }

            Section("智能数据") {

                ForEach(
                    TemplateVariableLibrary.intelligent
                ) { variable in

                    variableButton(
                        variable
                    )
                }
            }

            Section("用户数据") {

                ForEach(
                    TemplateVariableLibrary.user
                ) { variable in

                    variableButton(
                        variable
                    )
                }
            }
        }
        .navigationTitle("Variables")
    }

    private func variableButton(
        _ variable: TemplateVariable
    ) -> some View {

        Button {

            onSelect(variable)

        } label: {

            HStack {

                Text(variable.title)

                Spacer()

                Text(variable.token)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}
