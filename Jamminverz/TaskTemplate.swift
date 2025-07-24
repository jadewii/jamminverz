//
//  TaskTemplate.swift
//  Todomai Watch App
//
//  Created for task template model
//

import Foundation

struct TaskTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let tasks: [String]
}