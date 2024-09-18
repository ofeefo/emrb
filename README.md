# Easy Metrics (rb)
This project provides a facility for instrumenting applications with [Prometheus](https://github.com/prometheus/client_ruby) metrics.


## Usage
### [Examples TL;DR](./example)

Add the gem to your project:
```
  bundle add emrb
```


### Basic usage
```ruby
require "emrb"

class Metrics
  # Emrb::Instruments provides all necessary methods for creating instruments.
  include Emrb::Instruments  
  # Instruments can be defined as the following:
  counter :my_counter
end

# Perform measurements.
Metrics.my_counter.inc
```

## Features
### Supported metrics
All [Prometheus metrics](https://github.com/prometheus/client_ruby?tab=readme-ov-file#metrics) 
are supported and can be created the same way as in the example above.

### Providing metric-specific configs
Most of the provided methods are nothing but a shorthand for creating instruments (with some facilities): 
```ruby
require "emrb"

class Metrics
  include Emrb::Instruments
  #                                          /-> All other options for each metric
  #                                          |   follow the original client's syntax.
  counter :my_counter, "this is my counter", labels: [:my_label]
  #   _________________/
  #   \_> This is the "docstring" value used for creating 
  #       metrics using the Prometheus client. 
  #       This is the only API-breaking option
  #       for enhancing usability. Defaults to "..." when absent. 
end
```

When your metric requires multiple options, a single line may become unwieldy. In such cases, you can use a block to define the metric config:
```ruby
require "emrb"

class Metrics
  include Emrb::Instruments
  
  # The block should return a hash containing all the desired options.
  # When a block is used, other options passed inline are ignored.
  histogram :my_histogram do
    {
      labels: [:label1, :label2],
      preset_labels: { label1: "bar" },  
      buckets: [0.9, 1.0, ...]
    }
  end
end
```

### Presets
If more than one of your metrics leverages the same `preset_labels`, the following is possible:
```ruby
require "emrb"

class Metrics
  include Emrb::Instruments
  
  # Apply preset labels to multiple metrics within a block.
  with_presets label_a: "value_a", label_b: "value_b" do
    counter :counter_a
    counter :counter_b, labels: [:label_c]
    #                    \_> You can continue configuring 
    #                        each metric as usual.
    #                        The preset labels will be merged
    #                        with the specific ones.
  end
end
# Metrics.counter_a.labels => [:label_a, :label_b]
# Metrics.counter_b.labels => [:label_a, :label_b, :label_c]
```

### Subsystems
You can organize your metrics into subsystems, allowing different components of your application to group related metrics:
```ruby
require "emrb"

class Metrics
  include Emrb::Instruments
  subsystem :http do
    histogram :request_duration, "duration of requests" do
      { labels: [:method, :path] }
    end
  end
  
  subsystem :postgres do
    #                    / -> Subsystems also accepts presets.
    #                   |
    subsystem :replica, op: "read" do
      counter :op_count
    end
    
    subsystem :master do
      counter :op_count, labels: [:op]
    end
  end
end
```

Metrics within a subsystem are scoped by the subsystem's name. To access metrics within a subsystem:
```ruby
Metrics.postgres.master.op_count
```

### Subsystem's metrics name
Metrics created within subsystems are prefixed with the subsystem's name. For example:
* The `request_duration` metric within the `http` subsystem  will be named `http_request_duration`
* The `op_count` metric of `postgres.master` will be named `postgres_master_op_count`.



## Exposing metrics
Both [`Prometheus::Middleware::Exporter`](https://github.com/prometheus/client_ruby/blob/main/lib/prometheus/middleware/exporter.rb) 
and [`Prometheus::Middleware::Collector`](https://github.com/prometheus/client_ruby/blob/main/lib/prometheus/middleware/collector.rb) 
are [Rack middlewares](https://github.com/rack/rack) included in this gem as `Emrb::Exporter` and `Emrb::Collector`.
<br>

If you're unfamiliar with how to use these middlewares, the [http example](./example/http/main.rb) provides a demonstration.

## Pushing metrics
```ruby
require "emrb"

class Metrics
  include Emrb::Instruments  
  counter :my_counter
end

# Perform measurements.
Metrics.my_counter.inc

# Push the current registry state to your gateway.
Metrics.push("example", gateway: "http://localhost:9091")
```

# License
```
The MIT License (MIT)

Copyright (c) 2024 Felipe Mariotti, Vito Sartori

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
