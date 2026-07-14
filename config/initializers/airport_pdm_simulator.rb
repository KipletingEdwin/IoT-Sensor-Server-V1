
require 'concurrent-ruby'

$airport_fleet = Concurrent::Hash.new

# FLEET_SCHEMA = {

#   "Baggage_Bot_01"   => { name: "Baggage Bot 01 (Terminal 2)", base_vib: 1.5, base_curr: 4.0 },
#   "Baggage_Bot_02"   => { name: "Baggage Bot 02 (Terminal 2)", base_vib: 1.6, base_curr: 4.1 },
#   "Baggage_Bot_03"   => { name: "Baggage Bot 03 (Terminal 5)", base_vib: 1.4, base_curr: 3.9 },
#   "Baggage_Bot_04"   => { name: "Baggage Bot 04 (Terminal 5)", base_vib: 1.5, base_curr: 4.2 },
#   "Baggage_Bot_05"   => { name: "Baggage Bot 05 (Cargo Hub)",  base_vib: 1.8, base_curr: 4.5 },
#   "Baggage_Bot_06"   => { name: "Baggage Bot 06 (Cargo Hub)",  base_vib: 1.7, base_curr: 4.4 },
#   "Baggage_Bot_07"   => { name: "Baggage Bot 07 (Maintenance)", base_vib: 1.5, base_curr: 4.0 },

#   "Passport_Gate_A1" => { name: "Passport Gate Alpha 1 (Arrivals)", base_vib: 0.4, base_curr: 2.0 },
#   "Passport_Gate_A2" => { name: "Passport Gate Alpha 2 (Arrivals)", base_vib: 0.4, base_curr: 2.0 },
#   "Passport_Gate_A3" => { name: "Passport Gate Alpha 3 (Arrivals)", base_vib: 0.3, base_curr: 1.9 },
#   "Passport_Gate_A4" => { name: "Passport Gate Alpha 4 (Arrivals)", base_vib: 0.4, base_curr: 2.1 },
#   "Passport_Gate_A5" => { name: "Passport Gate Alpha 5 (Arrivals)", base_vib: 0.5, base_curr: 2.2 },
#   "Passport_Gate_B1" => { name: "Passport Gate Beta 1 (Departures)", base_vib: 0.4, base_curr: 2.0 },
#   "Passport_Gate_B2" => { name: "Passport Gate Beta 2 (Departures)", base_vib: 0.4, base_curr: 2.0 },
#   "Passport_Gate_B3" => { name: "Passport Gate Beta 3 (Departures)", base_vib: 0.3, base_curr: 1.8 }
# }.freeze



FLEET_SCHEMA = {
    "BHS_CONV_T1_A"  => { type: "Baggage Handling System",        name: "Conveyor Belt Main Line A", base_vib: 1.5, base_curr: 4.0 },
    "PBB_GATE_A12"   => { type: "Passenger Boarding Bridge",      name: "Gate A12 Docking Bridge",  base_vib: 2.2, base_curr: 6.4 },
    "ESC_ARR_04"     => { type: "Escalator & Elevator",           name: "Arrivals Main Escalator 01",base_vib: 1.4, base_curr: 3.9 },
    "AGL_RUNWAY_02R" => { type: "Airfield Ground Lighting",       name: "Runway 27L Touchdown Loop", base_vib: 0.3, base_curr: 12.0 },
    "PCA_GATE_A01"   => { type: "Pre-Conditioned Air Unit",       name: "Stand A01 Climate Pod",     base_vib: 1.8, base_curr: 8.2 },
    "EGATE_ARR_14"   => { type: "Automated Passport Gate",        name: "Border Control E-Gate 14",  base_vib: 0.3, base_curr: 2.0 },

    "BHS_CONV_T1_A"  => { type: "Baggage Handling System",        name: "Conveyor Belt Main Line B", base_vib: 1.5, base_curr: 4.0 },
    "PBB_GATE_B05"   => { type: "Passenger Boarding Bridge",      name: "Gate B01 Docking Bridge",  base_vib: 2.5, base_curr: 6.5 },
    "ESC_ARR_01"     => { type: "Escalator & Elevator",           name: "Arrivals Main Escalator 03",base_vib: 1.1, base_curr: 3.8 },
    "AGL_RUNWAY_05R" => { type: "Airfield Ground Lighting",       name: "Runway 27R Touchdown Loop", base_vib: 0.2, base_curr: 12.0 },
    "PCA_GATE_C10"   => { type: "Pre-Conditioned Air Unit",       name: "Stand C10 Climate Pod",     base_vib: 1.8, base_curr: 8.2 },
    "EGATE_ARR_14"   => { type: "Automated Passport Gate",        name: "Passport_Gate_B3",  base_vib: 0.4, base_curr: 2.1 },

    "BHS_CONV_T1_A"  => { type: "Baggage Handling System",        name: "Conveyor Belt Main Line C", base_vib: 1.5, base_curr: 4.0 },
    "PBB_GATE_C10"   => { type: "Passenger Boarding Bridge",      name: "Gate C10 Docking Bridge",  base_vib: 2.0, base_curr: 6.6 },
    "ESC_ARR_06"     => { type: "Escalator & Elevator",           name: "Arrivals Main Escalator 04",base_vib: 1.3, base_curr: 3.7 },
    "AGL_RUNWAY_10R" => { type: "Airfield Ground Lighting",       name: "Runway 24L Touchdown Loop", base_vib: 0.4, base_curr: 12.0 },
    "PCA_GATE_B02"   => { type: "Pre-Conditioned Air Unit",       name: "Stand B02 Climate Pod",     base_vib: 1.8, base_curr: 8.2 },
    "EGATE_ARR_14"   => { type: "Automated Passport Gate",        name: "Passport_Gate_A5",  base_vib: 0.6, base_curr: 2.2 }
  }.freeze

  # Production-ready Python schema mapping only critical BHS assets
# BHS_FLEET_SCHEMA = {
#     # TERMINAL 1 ASSETS
#     "BHS_T1_CHECKIN_01": { "subsystem": "Check-in Feeder Conveyor","location": "Terminal 1 Departure Hall","base_vib": 1.2, "base_temp": 35.0, "base_curr": 3.5 },
#     "BHS_T1_MAIN_LINE_A": { "subsystem": "Main Collector Belt","location": "Terminal 1 Baggage Hall","base_vib": 1.6, "base_temp": 45.0, "base_curr": 7.5 },
#     "BHS_T1_MERGE_01": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 1 Sortation Area","base_vib": 2.2, "base_temp": 50.0, "base_curr": 9.0 },
#     "BHS_T1_CAROUSEL_01": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 1 Arrivals Hall","base_vib": 1.4, "base_temp": 40.0, "base_curr": 6.0 },

#     # TERMINAL 2 ASSETS
#     "BHS_T2_CHECKIN_01": {"subsystem": "Check-in Feeder Conveyor","location": "Terminal 2 Departure Hall","base_vib": 1.1, "base_temp": 34.0,"base_curr": 3.4},
#     "BHS_T2_MAIN_LINE_B": {"subsystem": "Main Collector Belt","location": "Terminal 2 Baggage Hall","base_vib": 1.5,"base_temp": 44.0,"base_curr": 7.2},
#     "BHS_T2_MERGE_02": {"subsystem": "High-Speed Merge Conveyor","location": "Terminal 2 Sortation Area","base_vib": 2.1,"base_temp": 52.0,"base_curr": 9.5},
#     "BHS_T2_CAROUSEL_02": {"subsystem": "Arrival Reclaim Carousel","location": "Terminal 2 Arrivals Hall","base_vib": 1.3,"base_temp": 39.0, "base_curr": 5.8}
# }


# Seed randomized operational ages and wear rates to create unique decay timelines
FLEET_SCHEMA.each do |asset_id, meta|

    starting_hours = rand(35.0..60.0).round(2)


  $airport_fleet[asset_id] = {
    id: asset_id,
    name: meta[:name],
    type: meta[:type],
    operating_hours: starting_hours, 
    maintenance_due_at_hours: 800.0,
    wear_beta: rand(0.010..0.024),               
    base_vib: meta[:base_vib],
    base_curr: meta[:base_curr],
    is_failing: 0
  }
end

Thread.new do
  sleep 2.0
  loop_interval_pace = 1.0 
  
  Rails.application.executor.wrap do
    loop do
      begin
        target_id = $airport_fleet.keys.sample
        asset = $airport_fleet[target_id]
        
        # Accumulate age linearly on each second step
        asset[:operating_hours] = (asset[:operating_hours] + 0.05).round(2)
        
        # Mathematical Core: Apply Exponential Degradation Curves
        hours = asset[:operating_hours]
        beta  = asset[:wear_beta]
        
        vib_drift  = 0.08 * Math.exp(beta * hours * 0.15)
        temp_drift = 0.50 * Math.exp(beta * hours * 0.18)
        curr_drift = 0.12 * Math.exp(beta * hours * 0.12)
        
        vibration_metric = [0.1, asset[:base_vib] + vib_drift  + rand(-0.2..0.2)].max.round(2)
        temp_metric      = [20.0, 35.0             + temp_drift + rand(-0.8..0.8)].max.round(1)
        current_metric   = [0.2, asset[:base_curr] + curr_drift + rand(-0.3..0.3)].max.round(2)
        
        # Binary validation logic check against failure limits
        if vibration_metric > 7.5 || temp_metric > 82.0 || current_metric > 14.0 
          asset[:is_failing] = 1
        end
        
        payload = {
          asset_id: asset[:id],
          asset_type: asset[:type],
          asset_name: asset[:name],
          maintenance_due_at_hours: asset[:maintenance_due_at_hours], # Broadcast the target to the UI
          telemetry: {
            motor_vibration: vibration_metric,
            internal_temp: temp_metric,
            current_draw: current_metric,
          },
          operating_hours: asset[:operating_hours],
          failure_imminent_label: asset[:is_failing],
          timestamp: Time.now.iso8601(3)
        }
        
        # Stream frame to WebSockets
        ActionCable.server.broadcast("airport_maintenance_stream", payload)
        
        # Append record to your primary dataset log file
        log_dir = Rails.root.join('log')
        Dir.mkdir(log_dir) unless Dir.exist?(log_dir)
        File.open(log_dir.join('airport_pdm_telemetry_historical.log'), 'a') do |f|
          f.puts(payload.to_json)
        end
        
      rescue => e
        Rails.logger.error "[Predictive Maintenance Simulation Exception]: #{e.message}"
      end
      
      sleep(loop_interval_pace)
    end
  end
end
