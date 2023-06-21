namespace solution
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation RandomAlternative() : Unit 
    {
        // Allocate a single qubit to represent all bits for an 8-bit number (or byte)
        use q = Qubit();

        // Declare a mutable array of 8 results to represents the 8 bits of a byte
        mutable results = new Result[8];

        // Loop through all of the bits in the byte
        for i in 0 .. Length(results) - 1
        {
            // Put the qubit into a superposition of 0 and 1
            H(q);

            // Measure the qubit and store the result in the array
            // at the correct index based on the loop counter
            set results w/= i <- MResetZ(q);
        }

        // Convert the array of binary results into an integer
        // which is a byte because we have 8 results
        let number = ResultArrayAsInt(results);

        // Output the resulting byte
        Message($"Random byte: {number}");
    }
}