module AccumulateStat
using SimJulia
using Distributions
using DataStructures

export accumulate , accAdd, accReport, resetAccumulate
 
##### Type : Accumulate ( Description, Average-time & Min & Max & Standard deviation and Variance)

    type accumulate
    
        text :: ASCIIString  

        initTime :: Float64    # Initialization time.

        lastTime :: Float64    # Last update time.
        lastValue :: Float64   # Value since last update.

        minValue:: Float64
        maxValue:: Float64
        sumValue:: Float64
        sum_compensation:: Float64
         
        # Constructor definition         
# As for Tally, do not use "Wait"
        function accumulate(text::ASCIIString, env::Environment)
            this = new() 
            this.text = text
            this.minValue = Inf         
            this.maxValue = -Inf
            this.lastValue = 0.0
            this.sumValue = 0.0
            this.sum_compensation = 0.0
            this.initTime = now(env)
            this.lastTime = now(env)
            return this
        end   

    end
    
    #Report for Runway
    function accReport(this::accumulate, env::Environment)
        this = accAdd(convert(Int64, this.lastValue), env, this);
        print("Report on Accumulate collector")
        if (this.text != "") 
            println(" : ", string(this.text))
        end
          println(" Simulation time: ",string(this.initTime)," to ",string(this.lastTime))
          println(" Minimum value: ",string(this.minValue),"\tMaximum value: ",string(this.maxValue))
          
          period = this.lastTime - this.initTime
          this = accAdd(convert(Int64, this.lastValue), env, this)
          print( " Average: ")
          println(period > 0.0 ? string(round(this.sumValue/period,3)) : "0.0")
          print("\n\n"); 
    end 
    
    
    #Update number of waiting airplanes
    function accAdd(x :: Int64, env::Environment, this::accumulate)
          y :: Float64
          t :: Float64
          time = now(env);
          if (x < this.minValue) 
            this.minValue = x
          end
          if (x > this.maxValue) 
            this.maxValue = x
          end
          
          y = this.lastValue*(time-this.lastTime) - this.sum_compensation
          t = this.sumValue + y
          this.sum_compensation = (t-this.sumValue)-y
          this.sumValue = t

          this.lastValue = x
          this.lastTime = time
          return this
    end
    
    function resetAccumulate(this::accumulate,env::Environment)


      this.text = ""
      this.minValue = Inf
      this.maxValue = -Inf
      this.lastValue = 0.0
      this.sumValue = 0.0
      this.sum_compensation = 0.0
      this.initTime = now(env)
      this.lastTime = now(env)
      
      return this

    end
    
end