namespace exercise
{
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation StateRotation() : Unit 
    {
        // TODO: Adjust the following code fragment
        // to change the probability from 75% to 15%.

        // Allocate a single qubit
        use q = Qubit();

        // Declare a number of samples and a mutable
        // count variable to keep track of measurements
        let numberOfSamples = 10000;
        mutable count = 0;

        // Loop over the number of samples
        for i in 1 .. numberOfSamples
        {
            // Apply a specific rotation around the Y axis
            // to force a 75% chance of measuring |1⟩
            Ry(2.0 * PI() / 3.0, q);

            // Measure the qubit and increment
            // the count if |1⟩ is measured
            set count += MResetZ(q) == One ? 1 | 0;
        }

        // Output a calculated probability based
        // on the count and number of samples
        Message($"Probability of measuring |1⟩ is {Round(IntAsDouble(count) / IntAsDouble(numberOfSamples) * 100.0)}%");
    }
}