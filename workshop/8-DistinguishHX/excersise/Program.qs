namespace excersise
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation DistinguishHX() : Unit 
    {
        // Run the H operation
        Solve(H);
        
        // Run the X operation
        Solve(X);
    }

    operation Solve( op: (Qubit => Unit)) : Unit
    {
        // TODO: Distuinguish between H and X by running the given operation
        // and use the Message function to output the result.
        // You are allowed to run the operation multiple times.
    }
}