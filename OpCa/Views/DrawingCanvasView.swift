import SwiftUI
import UIKit

struct DrawingCanvasView: View {
    @State private var viewModel = MNISTViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onAnalysisStarted: (MNISTViewModel) -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Tanımak İstediğiniz Rakamı Çizin")
                    .font(.title3.bold())
                    .padding(.top)
                
                // Çizim alanı
                CanvasView(paths: $viewModel.drawingPaths)
                    .frame(width: 280, height: 280)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 3)
                    .padding()
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { _ in })
                
                Text("Parmağınızla veya Apple Pencil ile çizebilirsiniz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Kontrol butonları
                HStack(spacing: 30) {
                    Button(action: {
                        viewModel.clearDrawing()
                    }) {
                        VStack {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("Temizle")
                                .font(.caption)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button(action: {
                        // Analiz sayfasına geçiş yap
                        viewModel.isDrawingMode = true
                        onAnalysisStarted(viewModel)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                            Text("Tanı")
                                .font(.headline)
                        }
                        .frame(width: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.drawingPaths.isEmpty)
                }
                .padding(.bottom)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Rakam Çizme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Hazır") {
                    if !viewModel.drawingPaths.isEmpty {
                        viewModel.isDrawingMode = true
                        onAnalysisStarted(viewModel)
                    }
                    dismiss()
                }
                .disabled(viewModel.drawingPaths.isEmpty)
            }
        }
    }
}

// UIKit kullanarak çizim canvas'ı
struct CanvasView: UIViewRepresentable {
    @Binding var paths: [UIBezierPath]
    
    func makeUIView(context: Context) -> DrawingUIView {
        let view = DrawingUIView()
        view.paths = paths
        view.delegate = context.coordinator
        
        // ScrollView içinde olsa bile çizim önceliğini belirle
        view.isExclusiveTouch = true
        
        return view
    }
    
    func updateUIView(_ uiView: DrawingUIView, context: Context) {
        uiView.paths = paths
        uiView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DrawingUIViewDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func drawingDidUpdate(paths: [UIBezierPath]) {
            DispatchQueue.main.async {
                self.parent.paths = paths
            }
        }
    }
}

protocol DrawingUIViewDelegate: AnyObject {
    func drawingDidUpdate(paths: [UIBezierPath])
}

class DrawingUIView: UIView {
    weak var delegate: DrawingUIViewDelegate?
    var paths: [UIBezierPath] = []
    private var currentPath: UIBezierPath?
    private var initialTouch: UITouch?
    private var isDrawing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        
        // Çizim önceliği için
        isUserInteractionEnabled = true
        isExclusiveTouch = true
        
        // Scroll engelleme
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gesture.minimumPressDuration = 0.01 // Anında tepki versin
        gesture.delegate = self
        addGestureRecognizer(gesture)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            disableEnclosingScrollViews()
        case .ended, .cancelled, .failed:
            enableEnclosingScrollViews(withDelay: 0.05) // Biraz gecikme ile scroll etkinleştir
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isDrawing = true
        initialTouch = touch
        let location = touch.location(in: self)
        
        // ScrollView etkileşimini geçici olarak engelle
        disableEnclosingScrollViews()
        
        currentPath = UIBezierPath()
        currentPath?.lineWidth = 15.0
        currentPath?.lineCapStyle = .round
        currentPath?.lineJoinStyle = .round
        currentPath?.move(to: location)
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let touch = touches.first, let path = currentPath else { return }
        let location = touch.location(in: self)
        
        // Çizim hareketini kontrol et - aşırı hızlı kaydırma girişlerini engelle
        if let initialTouch = initialTouch {
            let initialLocation = initialTouch.location(in: self)
            let distance = hypot(location.x - initialLocation.x, location.y - initialLocation.y)
            
            // Eğer ilk dokunuştan itibaren çok hızlı/uzağa hareket edildiyse, bu muhtemelen scroll girişimidir
            if distance > 100 && path.isEmpty {
                isDrawing = false
                currentPath = nil
                enableEnclosingScrollViews()
                return
            }
        }
        
        path.addLine(to: location)
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let path = currentPath else { 
            isDrawing = false
            initialTouch = nil
            enableEnclosingScrollViews()
            return 
        }
        
        isDrawing = false
        initialTouch = nil
        
        // ScrollView etkileşimini geri aç
        enableEnclosingScrollViews()
        
        paths.append(path)
        currentPath = nil
        delegate?.drawingDidUpdate(paths: paths)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dokunma iptal edilirse de çizimi tamamla ve ScrollView'ı geri aç
        isDrawing = false
        initialTouch = nil
        enableEnclosingScrollViews()
        
        if let path = currentPath {
            paths.append(path)
            currentPath = nil
            delegate?.drawingDidUpdate(paths: paths)
        }
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        
        for path in paths {
            path.stroke()
        }
        
        currentPath?.stroke()
    }
    
    func clear() {
        paths.removeAll()
        setNeedsDisplay()
        delegate?.drawingDidUpdate(paths: [])
    }
    
    // ScrollView etkileşimini devre dışı bırak
    private func disableEnclosingScrollViews() {
        var view: UIView? = self
        while view != nil {
            if let scrollView = view as? UIScrollView {
                scrollView.isScrollEnabled = false
            }
            view = view?.superview
        }
    }
    
    // ScrollView etkileşimini geri aç
    private func enableEnclosingScrollViews(withDelay delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var view: UIView? = self
            while view != nil {
                if let scrollView = view as? UIScrollView {
                    scrollView.isScrollEnabled = true
                }
                view = view?.superview
            }
        }
    }
}

extension DrawingUIView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Kendi jest tanıyıcımıza öncelik ver
        return gestureRecognizer is UILongPressGestureRecognizer
    }
}

#Preview {
    NavigationStack {
        DrawingCanvasView { _ in }
    }
} 