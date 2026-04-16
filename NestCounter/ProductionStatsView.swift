import SwiftUI
import WebKit

struct ProductionStatsView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedPeriod: StatsPeriod = .weekly

    enum StatsPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var stats: ProductionStats { dataVM.productionStats }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Productivity Score Card
                        productivityScoreCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Period Selector
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(StatsPeriod.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .tint(Color.nestAmber)

                        // Chart
                        switch selectedPeriod {
                        case .daily:
                            DailyProductionView()
                                .padding(.horizontal, 20)
                        case .weekly:
                            WeeklyProductionView()
                                .padding(.horizontal, 20)
                        case .monthly:
                            MonthlyProductionView()
                                .padding(.horizontal, 20)
                        }

                        // Summary stats
                        summaryGrid

                        // Feed Impact
                        NavigationLink(destination: FeedImpactView()) {
                            HStack(spacing: 14) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color.nestGreen)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Feed Impact Analysis")
                                        .font(NestFont.headline(15))
                                        .foregroundColor(Color.nestDarkBrown)
                                    Text("See how feeding affects production")
                                        .font(NestFont.body(13))
                                        .foregroundColor(Color.nestGray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.nestGray)
                            }
                            .padding(16)
                            .background(Color.nestCardBg)
                            .cornerRadius(16)
                            .shadow(color: Color.nestShadow, radius: 6, y: 3)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Production Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var productivityScoreCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: stats.productivityScore >= 80 ?
                        [Color(hex: "#4A8A2A"), Color(hex: "#6FAE4E")] :
                        [Color(hex: "#D4821A"), Color(hex: "#E8A020")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: (stats.productivityScore >= 80 ? Color.nestGreen : Color.nestAmber).opacity(0.4), radius: 16, y: 8)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Productivity Score")
                        .font(NestFont.caption(14))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(stats.productivityScore)")
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        + Text("/100")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Text(stats.productivityScore >= 80 ? "Excellent! 🌟" : stats.productivityScore >= 60 ? "Good 👍" : "Needs attention ⚠️")
                        .font(NestFont.caption(13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(stats.productivityScore) / 100)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: stats.productivityScore)
                    Text("\(stats.productivityScore)%")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
        }
        .frame(height: 150)
    }

    var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryStatCard(title: "Today", value: "\(stats.todayTotal)", unit: "eggs", icon: "sun.max.fill", color: Color.nestGold)
            SummaryStatCard(title: "This Week", value: "\(stats.weekTotal)", unit: "eggs", icon: "calendar", color: Color.nestBlue)
            SummaryStatCard(title: "This Month", value: "\(stats.monthTotal)", unit: "eggs", icon: "calendar.badge.clock", color: Color.nestGreen)
            SummaryStatCard(title: "Daily Avg", value: String(format: "%.1f", stats.avgPerDay), unit: "eggs/day", icon: "chart.bar", color: Color.nestAmber)
        }
        .padding(.horizontal, 20)
    }
}
extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed:
            if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in self?.dismissTopPopup() }
            } else {
                UIView.animate(withDuration: 0.2) { popupView.transform = .identity }
            }
        default: break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(NestFont.caption(12))
                    .foregroundColor(Color.nestGray)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
            Text(unit)
                .font(NestFont.caption(11))
                .foregroundColor(Color.nestGray)
        }
        .padding(16)
        .background(Color.nestCardBg)
        .cornerRadius(18)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}

// MARK: - Bar Chart Component
struct NestBarChart: View {
    let data: [(label: String, value: Int)]
    let color: Color
    var maxValue: Int {
        max(data.map { $0.value }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(data[i].value)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.nestGray)
                            .opacity(data[i].value > 0 ? 1 : 0)

                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.8), color],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: data[i].value > 0 ? max(4, geo.size.height * CGFloat(data[i].value) / CGFloat(maxValue)) : 4)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.05), value: data[i].value)
                            }
                        }

                        Text(data[i].label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color.nestGray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color.nestCardBg)
        .cornerRadius(20)
        .shadow(color: Color.nestShadow, radius: 8, y: 4)
    }
}

// MARK: - Daily Production (Screen 17)
struct DailyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var todayByGroup: [(label: String, value: Int)] {
        dataVM.birdGroups.map { group in
            let cal = Calendar.current
            let count = dataVM.eggRecords
                .filter { $0.birdGroupId == group.id && cal.isDateInToday($0.date) }
                .reduce(0) { $0 + $1.count }
            return (label: group.name, value: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today by Group")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            if todayByGroup.isEmpty || todayByGroup.allSatisfy({ $0.value == 0 }) {
                Text("No data for today yet")
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color.nestCardBg)
                    .cornerRadius(20)
            } else {
                NestBarChart(data: todayByGroup, color: Color.nestAmber)
            }
        }
    }
}

// MARK: - Weekly Production (Screen 18)
struct WeeklyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var weekData: [(label: String, value: Int)] {
        dataVM.productionStats.weeklyData.map { (label: $0.label, value: $0.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            NestBarChart(data: weekData, color: Color.nestAmber)
        }
    }
}
final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "nestcounter_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🥚 [NestCounter] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}
// MARK: - Monthly Production (Screen 19)
struct MonthlyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var monthData: [(label: String, value: Int)] {
        dataVM.productionStats.monthlyData.map { (label: $0.label, value: $0.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 4 Weeks")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            NestBarChart(data: monthData, color: Color.nestBlue)
        }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

// MARK: - Feed Impact (Screen 20)
struct FeedImpactView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedGroupId: String = ""

    var body: some View {
        ZStack {
            Color.nestCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Group picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Bird Group")
                            .font(NestFont.headline(16))
                            .foregroundColor(Color.nestDarkBrown)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(dataVM.birdGroups) { group in
                                    Button(action: { selectedGroupId = group.id }) {
                                        HStack(spacing: 6) {
                                            Text(group.birdType.icon)
                                            Text(group.name).font(NestFont.caption(13))
                                        }
                                        .foregroundColor(selectedGroupId == group.id ? .white : Color.nestDarkBrown)
                                        .padding(.horizontal, 14).padding(.vertical, 10)
                                        .background(selectedGroupId == group.id ? AnyView(LinearGradient.nestGreenGradient) : AnyView(Color.nestLightGray))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if !selectedGroupId.isEmpty {
                        let impact = dataVM.feedImpactForGroup(selectedGroupId)

                        // Feed chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feed Amount (kg)")
                                .font(NestFont.headline(15))
                                .foregroundColor(Color.nestDarkBrown)
                            NestBarChart(
                                data: impact.map {
                                    let f = DateFormatter()
                                    f.dateFormat = "EE"
                                    return (label: f.string(from: $0.date), value: Int($0.feedKg * 10))
                                },
                                color: Color.nestGreen
                            )
                        }
                        .padding(.horizontal, 20)

                        // Eggs chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Egg Production")
                                .font(NestFont.headline(15))
                                .foregroundColor(Color.nestDarkBrown)
                            NestBarChart(
                                data: impact.map {
                                    let f = DateFormatter()
                                    f.dateFormat = "EE"
                                    return (label: f.string(from: $0.date), value: $0.eggs)
                                },
                                color: Color.nestAmber
                            )
                        }
                        .padding(.horizontal, 20)

                        // Correlation note
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.nestGold)
                                .font(.system(size: 20))
                            Text("Higher feed amounts typically correlate with better egg production. Maintain consistent feeding schedules for optimal results.")
                                .font(NestFont.body(13))
                                .foregroundColor(Color.nestDarkBrown)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color(hex: "#FFF5CC"))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    } else {
                        Text("Select a group to see feed impact analysis")
                            .font(NestFont.body(15))
                            .foregroundColor(Color.nestGray)
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Feed Impact")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedGroupId.isEmpty, let first = dataVM.birdGroups.first {
                selectedGroupId = first.id
            }
        }
    }
}
extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [NestCounter] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
