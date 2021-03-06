/// Prometheus Counter metric
///
/// See https://prometheus.io/docs/concepts/metric_types/#counter
public class Counter<NumType: Numeric, Labels: MetricLabels>: Metric, PrometheusHandled {
    /// Prometheus instance that created this Counter
    internal let prometheus: PrometheusClient
    
    /// Name of the Counter, required
    public let name: String
    /// Help text of the Counter, optional
    public let help: String?
    
    /// Type of the metric, used for formatting
    public let _type: MetricType = .counter
    
    /// Current value of the counter
    internal var value: NumType
    
    /// Initial value of the counter
    private var initialValue: NumType
    
    /// Storage of values that have labels attached
    internal var metrics: [Labels: NumType] = [:]
    
    /// Creates a new instance of a Counter
    ///
    /// - Parameters:
    ///     - name: Name of the Counter
    ///     - help: Helpt text of the Counter
    ///     - initialValue: Initial value to set the counter to
    ///     - p: Prometheus instance that created this counter
    internal init(_ name: String, _ help: String? = nil, _ initialValue: NumType = 0, _ p: PrometheusClient) {
        self.name = name
        self.help = help
        self.initialValue = initialValue
        self.value = initialValue
        self.prometheus = p
    }
    
    /// Gets the metric string for this counter
    ///
    /// - Returns:
    ///     Newline seperated Prometheus formatted metric string
    public func getMetric(_ done: @escaping (String) -> Void) {
        prometheusQueue.async(flags: .barrier) {
            var output = [String]()
            
            if let help = self.help {
                output.append("# HELP \(self.name) \(help)")
            }
            output.append("# TYPE \(self.name) \(self._type)")
            
            output.append("\(self.name) \(self.value)")
            
            self.metrics.forEach { (labels, value) in
                let labelsString = encodeLabels(labels)
                output.append("\(self.name)\(labelsString) \(value)")
            }
            
            done(output.joined(separator: "\n"))
        }
    }
    
    /// Increments the Counter
    ///
    /// - Parameters:
    ///     - amount: Amount to increment the counter with
    ///     - labels: Labels to attach to the value
    ///
    public func inc(_ amount: NumType = 1, _ labels: Labels? = nil, _ done: @escaping (NumType) -> Void = { _ in }) {
        prometheusQueue.async(flags: .barrier) {
            if let labels = labels {
                var val = self.metrics[labels] ?? self.initialValue
                val += amount
                self.metrics[labels] = val
                done(val)
            } else {
                self.value += amount
                done(self.value)
            }
        }
    }
    
    /// Gets the value of the Counter
    ///
    /// - Parameters:
    ///     - labels: Labels to get the value for
    ///
    /// - Returns: The value of the Counter attached to the provided labels
    public func get(_ labels: Labels? = nil) -> NumType {
        if let labels = labels {
            return self.metrics[labels] ?? initialValue
        } else {
            return self.value
        }
    }
}

