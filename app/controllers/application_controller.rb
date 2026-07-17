

class ApplicationController < ActionController::API

    def download_csv
        csv_path = Rails.root.join('log', 'bhs_ml_training_data.csv')

        if File.exist?(csv_path)
            #Send the file immediately as a sytem download stream
            send_file(
                csv_path,
                filename: "bhs_simulation_export_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv",
                type: 'text/csv',
                disposition: 'attachment'
            )
            else
                render json: { error: "Simulation dataset not found. Please run the simulation loop first."}, status: :not_found 
            end
    end

end
