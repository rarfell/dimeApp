//
//  LineGraph.swift
//  dime
//
//  Created by Rafael Soh on 25/11/22.
//

import Foundation
import SwiftUI

// Custom View....
struct LineGraph: View {
    var data: [LineGraphDataPoint]
    var green: Bool
    var type: Int
    var range: Int

    @State var currentPlot: LineGraphDataPoint?

    @State var offset: CGSize = .zero

    @State var showPlot = false

    @State var translation: CGFloat = 0

    @GestureState var isDrag: Bool = false

    var color: Color {
        return green ? Color.IncomeGreen : Color.AlertRed
    }

    var overlayColor: Color {
        if let plot = currentPlot {
            let index = data.firstIndex(of: plot) ?? 0

            if data.count - range <= index {
                return color
            } else {
                return Color.Outline
            }
        } else {
            return color
        }
    }

    // Animating Graph
    @State var graphProgress: CGFloat = 0

    func getGradient(totalPoints: Double, range: Double) -> Gradient {
        let centreLocation = 1 - (range - 1) / (totalPoints - 1)
        let leftLocation = centreLocation - 0.01

        return Gradient(stops: [Gradient.Stop(color: Color.Outline, location: leftLocation),
                                Gradient.Stop(color: color, location: centreLocation)])
    }

    var body: some View {
        GeometryReader { proxy in

            let height = proxy.size.height
            let width = (proxy.size.width) / CGFloat(data.count - 1)
            let dataValues = data.map { $0.amount }

            let maxPoint = (dataValues.max() ?? 0.0)
            let minPoint = dataValues.min() ?? 0.0

            let points = data.enumerated().compactMap { item -> CGPoint in

                let progress = (item.element.amount - minPoint) / (maxPoint - minPoint)

                let pathHeight = progress * height

                // width..
                let pathWidth = width * CGFloat(item.offset)

                // Since we need peak to top not bottom...
                return CGPoint(x: pathWidth, y: -pathHeight + height)
            }

            ZStack {
                //
                AnimatedGraphPath(progress: graphProgress, points: points)
                    .fill(
                        // Gradient...
                        LinearGradient(gradient: getGradient(totalPoints: Double(data.count), range: Double(range)), startPoint: .leading, endPoint: .trailing)
                    )

//                 Path Bacground Coloring...
//                FillBG()
//                // Clipping the shape...
//                    .clipShape(
//
//                        Path{path in
//
//                            // drawing the points..
//                            path.move(to: CGPoint(x: 0, y: 0))
//
//                            path.addLines(points)
//
//                            path.addLine(to: CGPoint(x: proxy.size.width, y: height))
//
//                            path.addLine(to: CGPoint(x: 0, y: height))
//                        }
//                    )
//                    .opacity(graphProgress)
//
            }
            .overlay(
                // Drag Indiccator...
                VStack(spacing: 0) {
                    VStack(spacing: 1) {
                        if type < 4 {
                            Text(currentPlot?.dateString ?? "")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        } else {
                            Text(currentPlot?.monthString ?? "")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color.SubtitleText)
                        }

                        Text(currentPlot?.amountString ?? "")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.PrimaryText)
                    }
                    .frame(height: 33)
                    .padding(.horizontal, 7)
                    .background(Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 6))
                    .padding(.bottom, 4)
//                    Text(currentPlot?.dateString ?? "")
//                        .font(.caption.bold())
//                        .foregroundColor(Color.PrimaryText)
//                        .padding(.vertical,6)
//                        .frame(width: 100)
//                        .background(Color.SecondaryBackground,in: Capsule())
//                        .offset(x: translation < 10 ? 30 : 0)
//                        .offset(x: translation > (proxy.size.width - 60) ? -30 : 0)
//
//                    Rectangle()
//                        .fill(Color.SecondaryBackground)
//                        .frame(width: 1,height: 25)

                    DottedLine()

                        .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 2.5, height: 25)
                        .foregroundColor(overlayColor)

                    Circle()
                        .stroke(Color.PrimaryBackground, lineWidth: 2.5)
                        .background(Circle().fill(overlayColor))
                        .frame(width: 14, height: 11)
//                    Circle()
//                        .fill(color)

//                        .overlay(
//
//                            Circle()
//                                .fill(Color.DarkIcon.opacity(0.85))
//                                .frame(width: 6.5, height: 6.5)
//                        )

//                    Rectangle()
//                        .fill(Color.SecondaryBackground)
//                        .frame(width: 1,height: 50)
                }
                // Fixed Frame..
                // For Gesture Calculation...
                .frame(width: 80)
                // 170 / 2 = 85 - 15 => circle ring size...
                .offset(y: 6)
                .offset(offset)
                .opacity(showPlot ? 1 : 0),

                alignment: .bottomLeading
            )
            .contentShape(Rectangle())
            .gesture(DragGesture().onChanged { value in

                withAnimation { showPlot = true }

                let translation = value.location.x

                // Getting index...
                let index = max(min(Int((translation / width).rounded() + 1), data.count - 1), 0)

                currentPlot = data[index]
                self.translation = translation

                // removing half width...
                offset = CGSize(width: points[index].x - 40, height: points[index].y - height)

            }.onEnded { _ in

                withAnimation { showPlot = false }

            }.updating($isDrag, body: { _, out, _ in
                out = true
            }))
        }
        .padding(.horizontal, 10)
        .onChange(of: isDrag) { _ in
            if !isDrag {
                showPlot = false
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    graphProgress = 1
                }
            }
        }
        .onChange(of: data) { _ in

            // MARK: ReAnimating When ever Plot Data Updates

            graphProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    graphProgress = 1
                }
            }
        }
    }

//    @ViewBuilder
//    func FillBG()->some View{
//        let color = green ? Color.IncomeGreen : Color.AlertRed
//        Color.red
    ////        LinearGradient(colors: [
    ////
    ////            color
    ////                .opacity(0.3),
    ////            color
    ////                .opacity(0.2),
    ////            color
    ////                .opacity(0.1)]
    ////            + Array(repeating: color
    ////                .opacity(0.1), count: 4)
    ////            + Array(repeating:                     Color.clear, count: 2)
    ////            , startPoint: .top, endPoint: .bottom)
//    }
}

// MARK: Animated Path

struct AnimatedGraphPath: Shape {
    var progress: CGFloat
    var points: [CGPoint]
    var animatableData: CGFloat {
        get { return progress }
        set { progress = newValue }
    }

    func path(in _: CGRect) -> Path {
        Path { path in

            // drawing the points..
            path.move(to: CGPoint(x: 0, y: 0))

            path.addLines(points)
        }
        .trimmedPath(from: 0, to: progress)
        .strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        return path
    }
}
