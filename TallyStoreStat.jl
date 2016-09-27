module TallyStoreStat

using DataStructures


export tallyStore , add2TallyStore , resetTallyStore, quickSortServList , quickSortArrvList

##### Type : tallyStore 
    type tallyStore
        wServiceList::LinkedList
        arrivalTimeList::LinkedList
        # Constructor definition
        function tallyStore()
            tallyArray = new()
            tallyArray.wServiceList = nil()
            tallyArray.arrivalTimeList = nil()
            return tallyArray
        end
    end

    #Add a Tally object to tallyStore wServiceList
    function add2TallyStore(tallyArray :: tallyStore, X :: Float64, Y :: Float64)         
          tallyArray.wServiceList = cons(X, tallyArray.wServiceList)
          tallyArray.arrivalTimeList = cons(Y, tallyArray.arrivalTimeList)
          return tallyArray
    end     
    
    ##resetTallyStore tallyStore : used to reset tallyStore wServiceList
    function resetTallyStore(tallyArray :: tallyStore)
          tallyArray.wServiceList = nil()
          tallyArray.arrivalTimeList = nil()
          return tallyArray
    end    
    
    ##quickSort tallyStore : used to sort tallyStore wServiceList
    function quickSortServList(tallyArray :: tallyStore)      
          return sort(collect(tallyArray.wServiceList); alg=QuickSort)
    end
    
    ##quickSort tallyStore : used to sort tallyStore wServiceList
    function quickSortArrvList(tallyArray :: tallyStore)      
          return sort(collect(tallyArray.arrivalTimeList); alg=QuickSort)
    end
    
end