
require 'concurrent-ruby'
require 'csv'

$airport_fleet = Concurrent::Hash.new

fleet = {
      # TERMINAL 1 ASSETS
    "BHS_T1_CHECKIN_01": { "subsystem": "Check-in Feeder Conveyor","location": "Terminal 1 Departure Hall","base_vib": 1.2, "base_temp": 35.0, "base_curr": 3.5, "maintenance_due_at_hours": 800.0 },
    "BHS_T1_MAIN_LINE_A": { "subsystem": "Main Collector Belt","location": "Terminal 1 Baggage Hall","base_vib": 1.6, "base_temp": 45.0, "base_curr": 7.5, "maintenance_due_at_hours": 800.0 },
    "BHS_T1_MERGE_01": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 1 Sortation Area","base_vib": 2.2, "base_temp": 50.0, "base_curr": 9.0, "maintenance_due_at_hours": 600.0 },
    "BHS_T1_CAROUSEL_01": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 1 Arrivals Hall","base_vib": 1.4, "base_temp": 40.0, "base_curr": 6.0, "maintenance_due_at_hours": 1000.0 },

    # TERMINAL 2 ASSETS
    "BHS_T2_CHECKIN_01": {"subsystem": "Check-in Feeder Conveyor","location": "Terminal 2 Departure Hall","base_vib": 1.1, "base_temp": 34.0,"base_curr": 3.4, "maintenance_due_at_hours": 800.0},
    "BHS_T2_MAIN_LINE_B": {"subsystem": "Main Collector Belt","location": "Terminal 2 Baggage Hall","base_vib": 1.5,"base_temp": 44.0,"base_curr": 7.2, "maintenance_due_at_hours": 800.0},
    "BHS_T2_MERGE_02": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 2 Sortation Area","base_vib": 2.1,"base_temp": 52.0,"base_curr": 9.5, "maintenance_due_at_hours": 600.0},
    "BHS_T2_CAROUSEL_02": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 2 Arrivals Hall","base_vib": 1.3,"base_temp": 39.0, "base_curr": 5.8, "maintenance_due_at_hours": 1000.0}
}.freeze

SIMULATION_START_TIME = Time.now
CSV_PATH = Rails.root.join('log', 'bhs_ml_training_data.csv')


# Initialize CSV headers if file doesn't exist
unless File.exist?(CSV_PATH)
  CSV.open(CSV_PATH, "wb") do |csv|
    csv << ["timestamp", "asset_id", "vibration", "temperature", "current", "state_label"]
  end
end


fleet.each do |asset_id, meta|
  $airport_fleet[asset_id] = {
    id: asset_id,
    name: meta[:subsystem],
    base_vib: meta[:base_vib],
    base_temp: meta[:base_temp],
    base_curr: meta[:base_curr],
    # Give each asset a different timeline speed so they don't all fail at once
    failure_acceleration: rand(0.015..0.035)
  }
end

Thread.new do
  loop_interval_pace = 2    #2s interval request
  
  Rails.application.executor.wrap do
    loop do
      begin
        csv_rows = []
        elapsed_seconds = Time.now - SIMULATION_START_TIME
        
        $airport_fleet.each do |asset_id, asset|
          # Accelerate time to simulate hours of degradation in minutes of wall-clock time
          simulated_hours = elapsed_seconds * asset[:failure_acceleration]
          
          # --- ISO 10816 & PHYSICS STATE MACHINE ---
          if simulated_hours < 10.0
            # STATE 0: Normal Operation (Stable baseline + industrial noise)
            state_label = "Normal"
            vib_metric   = asset[:base_vib]  + rand(-0.15..0.15)
            temp_metric  = asset[:base_temp] + rand(-0.4..0.4)
            curr_metric  = asset[:base_curr] + rand(-0.2..0.2)
            
          elsif simulated_hours >= 10.0 && simulated_hours < 22.0
            # STATE 1: Degradation (ISO 10816 Zone C: Unacceptable for long-term operation)
            state_label = "Degradation"
            # Linear/exponential drift to simulate belt tearing and friction
            drift_factor = (simulated_hours - 10.0)
            vib_metric   = asset[:base_vib]  + (drift_factor * 0.25) + rand(-0.3..0.3)
            temp_metric  = asset[:base_temp] + (drift_factor * 1.8)  + rand(-0.8..0.8)
            curr_metric  = asset[:base_curr] + (drift_factor * 0.3)  + rand(-0.4..0.4)
            
          else
            # STATE 2: Critical Failure (ISO 10816 Zone D: Danger of structural damage / Belt Jam)
            state_label = "Failure"
            # Abrupt, severe spikes mimicking a physical system lockup
            vib_metric   = 7.0  + rand(0.5..2.5)
            temp_metric  = 78.0 + rand(1.0..9.0)
            curr_metric  = 13.5 + rand(0.5..3.0)
          end
          
          # Clamp values to logical boundaries
          vib_final  = [0.1, vib_metric].max.round(2)
          temp_final = [20.0, temp_metric].max.round(1)
          curr_final = [0.1, curr_metric].max.round(2)
          simulated_hours_left = [10.0 - simulated_hours, 0.0].max
          
          payload = {
            asset_id: asset[:id],
            asset_name: asset[:name],
            telemetry: {
              motor_vibration: vib_final,
              internal_temp: temp_final,
              current_draw: curr_final,
            },
            state_label: state_label,
            hours_until_maintenance: simulated_hours_left.round(2),
            timestamp: Time.now.iso8601(3)
          }
          
          #  Stream live data down to React frontend
          ActionCable.server.broadcast("airport_maintenance_stream", payload)
          
          # 2. Cache row for batch-writing to CSV
          csv_rows << [payload[:timestamp], payload[:asset_id], vib_final, temp_final, curr_final, state_label]
        end
        
        # Write all asset ticks to the CSV at once to avoid system bottlenecks
        CSV.open(CSV_PATH, "a") do |csv|
          csv_rows.each { |row| csv << row }
        end
        
      rescue => e
        Rails.logger.error "[BHS Predictive Maintenance Error]: #{e.message}"
      end
      
      sleep(loop_interval_pace)
    end
  end
end












# require 'concurrent-ruby'
# require 'csv'

# $airport_fleet = Concurrent::Hash.new

# fleet = {
#     # TERMINAL 1 ASSETS
#     "BHS_T1_CHECKIN_01": { "subsystem": "Check-in Feeder Conveyor","location": "Terminal 1 Departure Hall","base_vib": 1.2, "base_temp": 35.0, "base_curr": 3.5, "maintenance_due_at_hours": 800.0 },
#     "BHS_T1_MAIN_LINE_A": { "subsystem": "Main Collector Belt","location": "Terminal 1 Baggage Hall","base_vib": 1.6, "base_temp": 45.0, "base_curr": 7.5, "maintenance_due_at_hours": 800.0 },
#     "BHS_T1_MERGE_01": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 1 Sortation Area","base_vib": 2.2, "base_temp": 50.0, "base_curr": 9.0, "maintenance_due_at_hours": 600.0 },
#     "BHS_T1_CAROUSEL_01": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 1 Arrivals Hall","base_vib": 1.4, "base_temp": 40.0, "base_curr": 6.0, "maintenance_due_at_hours": 1000.0 },

#     # TERMINAL 2 ASSETS
#     "BHS_T2_CHECKIN_01": {"subsystem": "Check-in Feeder Conveyor","location": "Terminal 2 Departure Hall","base_vib": 1.1, "base_temp": 34.0,"base_curr": 3.4, "maintenance_due_at_hours": 800.0},
#     "BHS_T2_MAIN_LINE_B": {"subsystem": "Main Collector Belt","location": "Terminal 2 Baggage Hall","base_vib": 1.5,"base_temp": 44.0,"base_curr": 7.2, "maintenance_due_at_hours": 800.0},
#     "BHS_T2_MERGE_02": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 2 Sortation Area","base_vib": 2.1,"base_temp": 52.0,"base_curr": 9.5, "maintenance_due_at_hours": 600.0},
#     "BHS_T2_CAROUSEL_02": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 2 Arrivals Hall","base_vib": 1.3,"base_temp": 39.0, "base_curr": 5.8, "maintenance_due_at_hours": 1000.0}
# }.freeze

# # Track global start time to replace operating_hours tracking
# SIMULATION_START_TIME = Time.now

# fleet.each do |asset_id, meta|
#   $airport_fleet[asset_id] = {
#     id: asset_id,
#     name: meta[:subsystem],
#     maintenance_due_at_hours: meta[:maintenance_due_at_hours], 
#     wear_beta: rand(0.010..0.024),               
#     base_vib: meta[:base_vib],
#     base_curr: meta[:base_curr],
#     is_failing: 0
#   }
# end

# Thread.new do
#   sleep 2.0
#   loop_interval_pace = 1.0 
  
#   Rails.application.executor.wrap do
#     loop do
#       begin
#         target_id = $airport_fleet.keys.sample
#         asset = $airport_fleet[target_id]
        
#         # 3. Replaced operating_hours with elapsed simulation hours
#         elapsed_seconds = Time.now - SIMULATION_START_TIME
#         simulated_hours = (elapsed_seconds * 0.05).round(2) 
        
#         beta = asset[:wear_beta]
        
#         # Mathematical Core uses simulated_hours instead of asset[:operating_hours]
#         vib_drift  = 0.08 * Math.exp(beta * simulated_hours * 0.15)
#         temp_drift = 0.50 * Math.exp(beta * simulated_hours * 0.18)
#         curr_drift = 0.12 * Math.exp(beta * simulated_hours * 0.12)
        
#         vibration_metric = [0.1, asset[:base_vib] + vib_drift  + rand(-0.2..0.2)].max.round(2)
#         temp_metric      = [20.0, 35.0             + temp_drift + rand(-0.8..0.8)].max.round(1)
#         current_metric   = [0.2, asset[:base_curr] + curr_drift + rand(-0.3..0.3)].max.round(2)
        
#         if vibration_metric > 7.5 || temp_metric > 82.0 || current_metric > 14.0 
#           asset[:is_failing] = 1
#         end
        
#         payload = {
#           asset_id: asset[:id],
#           asset_name: asset[:name],
#           maintenance_due_at_hours: asset[:maintenance_due_at_hours], 
#           telemetry: {
#             motor_vibration: vibration_metric,
#             internal_temp: temp_metric,
#             current_draw: current_metric,
#           },
#           # 4. Removed operating_hours from payload entirely
#           failure_imminent_label: asset[:is_failing],
#           timestamp: Time.now.iso8601(3)
#         }
        
#         ActionCable.server.broadcast("airport_maintenance_stream", payload)
        
#         log_dir = Rails.root.join('log')
#         Dir.mkdir(log_dir) unless Dir.exist?(log_dir)
#         File.open(log_dir.join('airport_pdm_telemetry_historical.log'), 'a') do |f|
#           f.puts(payload.to_json)
#         end
        
#       rescue => e
#         Rails.logger.error "[Predictive Maintenance Simulation Exception]: #{e.message}"
#       end
      
#       sleep(loop_interval_pace)
#     end
#   end
# end

