module Geotab
  class Client
    AUTHENTICATION_URL = "https://my.geotab.com/apiv1/Authenticate"

    def authenticate(username, password, database=nil)
      response = Faraday.get(AUTHENTICATION_URL,
                             {userName: username, password: password, database: database})
      attributes = JSON.parse(response.body)

      @path = attributes["result"]["path"]
      @credentials = attributes["result"]["credentials"]
    end

    def devices
      response = Faraday.get("https://#{@path}/apiv1/Get",
                             {typeName: "Device", credentials: credentials})
      attributes = JSON.parse(response.body)

      devices = []
      attributes.to_ostruct_recursive.result.each do |device|
        devices.push(Device.new(device, self))
      end

      devices
    end

    def last_odometer_reading(device_id, from_date = Date.today - 1, to_date = Date.today)
      response = Faraday.get("https://#{@path}/apiv1/Get",
                             {typeName: "StatusData",
                              credentials: credentials,
                              search: "{'deviceSearch':{'id':'#{device_id}'},'diagnosticSearch':{'id':'DiagnosticOdometerAdjustmentId'},'fromDate':'#{(from_date).to_s}'}"})
      attributes = JSON.parse(response.body)
      readings = attributes.to_ostruct_recursive.result

      reading = readings.last(2).first # the last one is usually junk

      mi = (reading.data / 1609.344).to_i
      km = (reading.data / 1000).to_i

      puts "\n********#{reading.inspect}"
      {mi: mi, km: km, date: reading.dateTime}
    end

    def credentials
      "{'database':'#{@credentials['database']}','userName':'#{@credentials['userName']}','sessionId':'#{@credentials['sessionId']}'}"
    end

    def path
      @path
    end
  end
end