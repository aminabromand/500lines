/**
  *  flow.als
  *    A model of how differet data elements flow from one component to another
  *    as an argument or return type in calls
  */
module flow

open http
open jsonp
open postMessage
open setDomain
open script


sig Data in Resource + Cookie {}

sig FlowCall in Call {
  args, returns: set Data,  -- arguments and return data of this call
}{
  -- Two general constrains about dataflow calls
  -- (1) Any arguments must be accessible to the sender
  args in from.accesses.start
  -- (2) Any data returned from this call must be accessible to the receiver
  returns in to.accesses.start

  -- Constraints about particular operations
  this in HttpRequest implies
    args = this.sentCookies + this.body and
    returns = this.receivedCookies + this.response

  -- BrowserOp
  this in ReadDom implies no args and returns = this.result
  this in WriteDom implies args = this.newDom and no returns
  this in SetDomain implies no args + returns
  this in PostMessage implies args = this.message and no returns

  -- EventHandler
  this in JsonpCallback implies args = this.payload and no returns
  this in ReceiveMessage implies args = this.data and no returns
}

sig FlowModule in Endpoint {
  -- Set of data that this component initally owns
  accesses: Data -> Time
}{
  all d: Data, t: Time - first |
	 -- This endpoint can only access a piece of data "d" at time "t" only when
    d -> t in accesses implies
      -- (1) It already had access in the previous time step, or
      d -> t.prev in accesses or
      -- there is some call "c" that ended at "t" such that
      some c: Call & end.t |
        -- (2) the endpoint receives "c" that carries "d" as one of its arguments or
        c.to = this and d in c.args or
        -- (3) the endpoint sends "c" that returns d" 
        c.from = this and d in c.returns 
}

fun initData[m: FlowModule] : set Data {
  m.accesses.first
}

run {
  some Client.accesses
} for 3
