module TallyStat
using SimJulia


export tally , tallyAdd , tallyReport, resetTally


##### Type : Tally
    type tally
        text :: ASCIIString
        nobs:: Int64
        currentAverage:: Float64 # current observations average
        minValue:: Float64  # minimum of the observations
        maxValue:: Float64  # maximum of the observations
        sumValue:: Float64  # sum of the observations
        sumSquares:: Float64 # sum of the square of the observations
        currentSum2:: Float64 
        
        # Constructor definition
        function tally(text::ASCIIString)
            this = new()
            this.text = text
            this.nobs = 0
            this.minValue = 99999999999999
            this.maxValue = -10
            this.sumValue = 0.0
            this.sumSquares = 0.0
            this.currentSum2 = 0.0
            this.currentAverage = 0.0
            return this
        end
    end    
   
    function tallyReport( this :: tally )
        print("Report on Tally")
        if (this.text != "") 
            println(" : ",string(this.text))
        end
          println(" Number of observations: ",string(this.nobs))
          println(" Minimum: ",string(round(this.minValue,3)),"\tMaximum: ",string(round(this.maxValue,3)))
          
          tallyAverage = this.nobs > 0 ? this.currentAverage : NaN
          tallyVariance = this.nobs > 1 ? this.currentSum2/(this.nobs - 1) : NaN
          tallyStdv = this.nobs > 1 ? sqrt(tallyVariance) : NaN
          println(" Average: ",string(round(tallyAverage,3)),"\tStandard deviation: ",string(round(tallyStdv,3)))
    end

    function tallyAdd(x :: Float64, this :: tally)
          delta :: Float64
          
          if (x < this.minValue) 
            this.minValue = x
          end
          if (x > this.maxValue) 
            this.maxValue = x
          end
          this.nobs += 1
          this.sumValue += x
          this.sumSquares += x*x
          delta = x - this.currentAverage
          this.currentAverage += delta/this.nobs
          this.currentSum2 += delta*(x-this.currentAverage)
          return this
    end
    
    function resetTally(this::tally)  
 
      this.text = ""
      this.nobs = 0
      this.minValue = Inf
      this.maxValue = -Inf
      this.sumValue = 0.0
      this.sumSquares = 0.0
      this.currentSum2 = 0.0
      this.currentAverage = 0.0
      
      return this

    end

end