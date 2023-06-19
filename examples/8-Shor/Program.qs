﻿// SOURCE
// https://github.com/microsoft/Quantum
// https://github.com/microsoft/Quantum/tree/main/samples/algorithms/integer-factorization

namespace Shor
{
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Characterization;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Oracles;
    open Microsoft.Quantum.Random;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Introduction ///////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////

    // This sample contains Q# code implementing Shor's quantum algorithm for
    // factoring integers. The implementation is based on a paper by Stephane
    // Beauregard who gave a quantum circuit for factoring n-bit numbers that
    // needs 2n+3 qubits and O(n³log(n)) elementary quantum gates.
    // Instead of using Fourier based arithmetic, we use the addition circuit
    // by Gidney, which makes use of auxiliary qubits but is expected to
    // outperform Fourier based arithmetic in a fault-tolerant setting due to
    // the cost of rotation synthesis and magic state distillation.

    /// # Summary
    /// Uses Shor's algorithm to factor the parameter `number`
    ///
    /// # Input
    /// ## number
    /// A semiprime integer to be factored
    ///
    /// # Output
    /// Pair of numbers p > 1 and q > 1 such that p⋅q = `number`
    operation FactorSemiprimeInteger(number : Int)
    : (Int, Int) {
        // First check the most trivial case, if the provided number is even
        if number % 2 == 0 {
            Message("An even number has been given; 2 is a factor.");
            return (number / 2, 2);
        }
        // These mutables will keep track of if we found the factors,
        // and if so, what they are. The default value for the factors
        // is (1,1).
        mutable foundFactors = false;
        mutable factors = (1, 1);

        repeat {
            // Next try to guess a number co-prime to `number`
            // Get a random integer in the interval [1,number-1]
            let generator = DrawRandomInt(1, number - 1);

            // Check if the random integer indeed co-prime using
            // Microsoft.Quantum.Math.IsCoprimeI.
            // If true use Quantum algorithm for Period finding.
            if IsCoprimeI(generator, number) {

                // Print a message using Microsoft.Quantum.Intrinsic.Message
                // indicating that we are doing something quantum.
                Message($"Estimating period of {generator}");

                // Call Quantum Period finding algorithm for
                // `generator` mod `number`.
                let period = EstimatePeriod(generator, number);

                // Set the flag and factors values if the continued fractions
                // classical algorithm succeeds.
                set (foundFactors, factors) = MaybeFactorsFromPeriod(number, generator, period);
            }
            // In this case, we guessed a divisor by accident.
            else {
                // Find a divisor using Microsoft.Quantum.Math.GreatestCommonDivisorI
                let gcd = GreatestCommonDivisorI(number, generator);

                // Don't forget to tell the user that we were lucky and didn't do anything
                // quantum by using Microsoft.Quantum.Intrinsic.Message.
                Message($"We have guessed a divisor of {number} to be {gcd} by accident.");

                // Set the flag `foundFactors` to true, indicating that we succeeded in finding
                // factors.
                set foundFactors = true;
                set factors = (gcd, number / gcd);
            }
        }
        until foundFactors
        fixup {
            Message("The estimated period did not yield a valid factor, trying again.");
        }

        // Return the factorization
        return factors;
    }

    /// # Summary
    /// Interprets `target` as encoding unsigned little-endian integer k
    /// and performs transformation |k⟩ ↦ |gᵖ⋅k mod N ⟩ where
    /// p is `power`, g is `generator` and N is `modulus`.
    ///
    /// # Input
    /// ## generator
    /// The unsigned integer multiplicative order ( period )
    /// of which is being estimated. Must be co-prime to `modulus`.
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    /// ## power
    /// Power of `generator` by which `target` is multiplied.
    /// ## target
    /// Register interpreted as LittleEndian which is multiplied by
    /// given power of the generator. The multiplication is performed modulo
    /// `modulus`.
    operation ApplyOrderFindingOracle(
        generator : Int, modulus : Int, power : Int, target : Qubit[]
    )
    : Unit
    is Adj + Ctl {
        // Check that the parameters satisfy the requirements.
        Fact(IsCoprimeI(generator, modulus), "`generator` and `modulus` must be co-prime");

        // The oracle we use for order finding implements |x⟩ ↦ |x⋅a mod N⟩.
        // The implementation details can be found in `Modular.qs`, `Compare.qs`
        // and `Add.qs`.
        // We also use Microsoft.Quantum.Math.ExpModI to compute a by which
        // x must be multiplied.
        // Also note that we interpret target as unsigned integer
        // in little-endian encoding by using Microsoft.Quantum.Arithmetic.LittleEndian
        // type.
        ModularMultiplyByConstant(IntAsBigInt(modulus),
                                  IntAsBigInt(ExpModI(generator, power, modulus)),
                                  LittleEndian(target));
    }

    /// # Summary
    /// Interprets `target` as encoding an unsigned little-endian integer k
    /// and performs transformation |k⟩ ↦ |gᵖ⋅k mod N⟩ where
    /// p is `power`, g is `generator` and N is `modulus` using
    /// Fourier based arithmetic.
    ///
    /// # Input
    /// ## generator
    /// The unsigned integer multiplicative order ( period )
    /// of which is being estimated. Must be co-prime to `modulus`.
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    /// ## power
    /// Power of `generator` by which `target` is multiplied.
    /// ## target
    /// Register interpreted as LittleEndian which is multiplied by
    /// given power of the generator. The multiplication is performed modulo
    /// `modulus`.
    operation ApplyOrderFindingOracleFourierArithmetic(
        generator : Int, modulus : Int, power : Int, target : Qubit[]
    )
    : Unit
    is Adj + Ctl {
        // Check that the parameters satisfy the requirements.
        Fact(IsCoprimeI(generator, modulus), "`generator` and `modulus` must be co-prime");

        // The oracle we use for order finding implements |x⟩ ↦ |x⋅a mod N ⟩.
        // Here, we forward to the library implementation, which uses Fourier based
        // arithmetic.
        MultiplyByModularInteger(ExpModI(generator, power, modulus), modulus, LittleEndian(target));
    }

    /// # Summary
    /// Finds a multiplicative order of the generator
    /// in the residue ring Z mod `modulus`.
    ///
    /// # Input
    /// ## generator
    /// The unsigned integer multiplicative order ( period )
    /// of which is being estimated. Must be co-prime to `modulus`.
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    ///
    /// # Output
    /// The period ( multiplicative order ) of the generator mod `modulus`
    operation EstimatePeriod(
        generator : Int, modulus : Int
    )
    : Int {
        // Here we check that the inputs to the EstimatePeriod operation are valid.
        Fact(IsCoprimeI(generator, modulus), "`generator` and `modulus` must be co-prime");

        // The variable that stores the divisor of the generator period found so far.
        mutable result = 1;

        // Number of bits in the modulus with respect to which we are estimating the period.
        let bitsize = BitSizeI(modulus);

        // The EstimatePeriod operation estimates the period r by finding an
        // approximation k/2^(bits precision) to a fraction s/r, where s is some integer.
        // Note that if s and r have common divisors we will end up recovering a divisor of r
        // and not r itself. However, if we recover enough divisors of r
        // we recover r itself pretty soon.

        // Number of bits of precision with which we need to estimate s/r to recover period r.
        // using continued fractions algorithm.
        let bitsPrecision = 2 * bitsize + 1;

        // A variable that stores our current estimate for the frequency
        // of the form s/r.
        mutable frequencyEstimate = 0;

        set frequencyEstimate = EstimateFrequency(
            generator, modulus, bitsize
        );

        if frequencyEstimate != 0 {
            set result = PeriodFromFrequency(modulus, frequencyEstimate, bitsPrecision, result);
        }
        else {
            Message("The estimated frequency was 0, trying again.");
        }
        return result;
    }

    /// # Summary
    /// Estimates the frequency of a generator
    /// in the residue ring Z mod `modulus`.
    ///
    /// # Input
    /// ## generator
    /// The unsigned integer multiplicative order ( period )
    /// of which is being estimated. Must be co-prime to `modulus`.
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    /// ## bitsize
    /// Number of bits needed to represent the modulus.
    ///
    /// # Output
    /// The numerator k of dyadic fraction k/2^bitsPrecision
    /// approximating s/r.
    operation EstimateFrequency(
        generator : Int,
        modulus : Int,
        bitsize : Int
    )
    : Int {
        mutable frequencyEstimate = 0;
        let bitsPrecision =  2 * bitsize + 1;

        // Allocate qubits for the superposition of eigenstates of
        // the oracle that is used in period finding.
        use eigenstateRegister = Qubit[bitsize];

        // Initialize eigenstateRegister to 1, which is a superposition of
        // the eigenstates we are estimating the phases of.
        // We first interpret the register as encoding an unsigned integer
        // in little endian encoding.
        let eigenstateRegisterLE = LittleEndian(eigenstateRegister);
        ApplyXorInPlace(1, eigenstateRegisterLE);
        let oracle = ApplyOrderFindingOracle(generator, modulus, _, _);

        // Use phase estimation with a semiclassical Fourier transform to
        // estimate the frequency.
        use c = Qubit();
        for idx in bitsPrecision - 1..-1..0 {
            within {
                H(c);
            } apply {
                Controlled oracle([c], (1 <<< idx, eigenstateRegisterLE!));
                R1Frac(frequencyEstimate, bitsPrecision - 1 - idx, c);
            }
            if MResetZ(c) == One {
                set frequencyEstimate += 1 <<< (bitsPrecision - 1 - idx);
            }
        }

        // Return all the qubits used for oracle's eigenstate back to 0 state
        // using Microsoft.Quantum.Intrinsic.ResetAll.
        ResetAll(eigenstateRegister);

        return frequencyEstimate;
    }

    /// # Summary
    /// Find the period of a number from an input frequency.
    ///
    /// # Input
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    /// ## frequencyEstimate
    /// The frequency that we want to convert to a period.
    /// ## bitsPrecision
    /// Number of bits of precision with which we need to
    /// estimate s/r to recover period r using continued
    /// fractions algorithm.
    /// ## currentDivisor
    /// The divisor of the generator period found so far.
    ///
    /// # Output
    /// The period as calculated from the estimated frequency via
    /// the continued fractions algorithm.
    ///
    /// # See Also
    /// - Microsoft.Quantum.Math.ContinuedFractionConvergentI
    function PeriodFromFrequency(
        modulus : Int,
        frequencyEstimate : Int,
        bitsPrecision : Int,
        currentDivisor : Int
    )
    : Int {

        // Now we use Microsoft.Quantum.Math.ContinuedFractionConvergentI
        // function to recover s/r from dyadic fraction k/2^bitsPrecision.
        let (numerator, period) = (ContinuedFractionConvergentI(Fraction(frequencyEstimate, 2 ^ bitsPrecision), modulus))!;

        // ContinuedFractionConvergentI does not guarantee the signs of the numerator
        // and denominator. Here we make sure that both are positive using
        // AbsI.
        let (numeratorAbs, periodAbs) = (AbsI(numerator), AbsI(period));

        // Return the newly found divisor.
        // Uses Microsoft.Quantum.Math.GreatestCommonDivisorI function from Microsoft.Quantum.Math.
        return (periodAbs * currentDivisor) / GreatestCommonDivisorI(currentDivisor, periodAbs);
    }

    /// # Summary
    /// Tries to find the factors of `modulus` given a `period` and `generator`.
    ///
    /// # Input
    /// ## modulus
    /// The modulus which defines the residue ring Z mod `modulus`
    /// in which the multiplicative order of `generator` is being estimated.
    /// ## generator
    /// The unsigned integer multiplicative order ( period )
    /// of which is being estimated. Must be co-prime to `modulus`.
    /// ## period
    /// The estimated period ( multiplicative order ) of the generator mod `modulus`.
    ///
    /// # Output
    /// A tuple of a flag indicating whether factors were found successfully,
    /// and a pair of integers representing the factors that were found.
    /// Note that the second output is only meaningful when the first
    /// output is `true`.
    ///
    /// # See Also
    /// - Microsoft.Quantum.Math.GreatestCommonDivisorI
    function MaybeFactorsFromPeriod(modulus : Int, generator : Int, period : Int)
    : (Bool, (Int, Int)) {
        // Period finding reduces to factoring only if period is even
        if period % 2 == 0 {
            // Compute `generator` ^ `period/2` mod `number`
            // using Microsoft.Quantum.Math.ExpModI.
            let halfPower = ExpModI(generator, period / 2, modulus);

            // If we are unlucky, halfPower is just -1 mod N,
            // which is a trivial case and not useful for factoring.
            if halfPower != modulus - 1 {
                // When the halfPower is not -1 mod N
                // halfPower-1 or halfPower+1 share non-trivial divisor with `number`.
                // We find a divisor Microsoft.Quantum.Math.GreatestCommonDivisorI.
                let factor = MaxI(
                    GreatestCommonDivisorI(halfPower - 1, modulus),
                    GreatestCommonDivisorI(halfPower + 1, modulus)
                );

                // Add a flag that we found the factors, and return computed non-trivial factors.
                return (true, (factor, modulus / factor));
            } else {
                // Return a flag indicating we hit a trivial case and didn't get any factors.
                return (false, (1, 1));
            }
        } else {
            // When period is odd we have to pick another generator to estimate
            // period of and start over.
            Message("Estimated period was odd, trying again.");
            return (false, (1, 1));
        }
    }

	/// # Summary
    /// Performs in-place addition of a constant into a quantum register.
    ///
    /// # Description
    /// Given a non-empty quantum register |𝑦⟩ of length 𝑛+1 and a positive
    /// constant 𝑐 < 2ⁿ, computes |𝑦 + c⟩ into |𝑦⟩.
    ///
    /// # Input
    /// ## c
    /// Constant number to add to |𝑦⟩.
    /// ## y
    /// Quantum register of second summand and target; must not be empty.
    operation AddConstant(c : BigInt, y : LittleEndian) : Unit is Adj + Ctl {
        // We are using this version instead of the library version that is based
        // on Fourier angles to show an advantage of sparse simulation in this sample.

        let n = Length(y!);
        Fact(n > 0, "Bit width must be at least 1");

        Fact(c >= 0L, "constant must not be negative");
        Fact(c < PowL(2L, n), $"constant must be smaller than {PowL(2L, n)}");

        if c != 0L {
            // If c has j trailing zeroes than the j least significant bits
            // of y won't be affected by the addition and can therefore be
            // ignored by applying the addition only to the other qubits and
            // shifting c accordingly.
            let j = NTrailingZeroes(c);
            use x = Qubit[n - j];
            let xReg = LittleEndian(x);
            within {
                ApplyXorInPlaceL(c >>> j, xReg);
            } apply {
                AddI(xReg, LittleEndian((y!)[j...]));
            }
        }
    }

    /// # Summary
    /// Performs modular in-place addition of a classical constant into a
    /// quantum register.
    ///
    /// # Description
    /// Given the classical constants `c` and `modulus`, and an input
    /// quantum register (as LittleEndian) |𝑦⟩, this operation
    /// computes `(x+c) % modulus` into |𝑦⟩.
    ///
    /// # Input
    /// ## modulus
    /// Modulus to use for modular addition
    /// ## c
    /// Constant to add to |𝑦⟩
    /// ## y
    /// Quantum register of target
    operation ModularAddConstant(modulus : BigInt, c : BigInt, y : LittleEndian)
    : Unit is Adj + Ctl {
        body (...) {
            Controlled ModularAddConstant([], (modulus, c, y));
        }
        controlled (ctrls, ...) {
            // We apply a custom strategy to control this operation instead of
            // letting the compiler create the controlled variant for us in which
            // the `Controlled` functor would be distributed over each operation
            // in the body.
            //
            // Here we can use some scratch memory to save ensure that at most one
            // control qubit is used for costly operations such as `AddConstant`
            // and `CompareGreaterThenOrEqualConstant`.
            if Length(ctrls) >= 2 {
                use control = Qubit();
                within {
                    Controlled X(ctrls, control);
                } apply {
                    Controlled ModularAddConstant([control], (modulus, c, y));
                }
            } else {
                use carry = Qubit();
                Controlled AddConstant(ctrls, (c, LittleEndian(y! + [carry])));
                Controlled Adjoint AddConstant(ctrls, (modulus, LittleEndian(y! + [carry])));
                Controlled AddConstant([carry], (modulus, y));
                Controlled CompareGreaterThanOrEqualConstant(ctrls, (c, y, carry));
            }
        }
    }

    /// # Summary
    /// Performs modular in-place multiplication by a classical constant.
    ///
    /// # Description
    /// Given the classical constants `c` and `modulus`, and an input
    /// quantum register (as LittleEndian) |𝑦⟩, this operation
    /// computes `(c*x) % modulus` into |𝑦⟩.
    ///
    /// # Input
    /// ## modulus
    /// Modulus to use for modular multiplication
    /// ## c
    /// Constant by which to multiply |𝑦⟩
    /// ## y
    /// Quantum register of target
    operation ModularMultiplyByConstant(modulus : BigInt, c : BigInt, y : LittleEndian)
    : Unit is Adj + Ctl {
        use qs = Qubit[Length(y!)];
        for (idx, yq) in Enumerated(y!) {
            let shiftedC = ModL(c <<< idx, modulus);
            Controlled ModularAddConstant([yq], (modulus, shiftedC, LittleEndian(qs)));
        }
        ApplyToEachCA(SWAP, Zipped(y!, qs));
        let invC = InverseModL(c, modulus);
        for (idx, yq) in Enumerated(y!) {
            let shiftedC = ModL(invC <<< idx, modulus);
            Controlled ModularAddConstant([yq], (modulus, modulus - shiftedC, LittleEndian(qs)));
        }
    }

	operation ApplyXorInPlaceL(value : BigInt, target : LittleEndian) : Unit is Adj+Ctl {
        let bits = BigIntAsBoolArray(value);
        let bitsPadded = Length(bits) > Length(target!) ? bits[...Length(target!) - 1] | bits;
        ApplyPauliFromBitString(PauliX, true, bitsPadded, (target!)[...Length(bitsPadded) - 1]);
    }

    internal function NTrailingZeroes(number : BigInt) : Int {
        mutable nZeroes = 0;
        mutable copy = number;
        while (copy % 2L == 0L) {
            set nZeroes += 1;
            set copy /= 2L;
        }
        return nZeroes;
    }

    internal function BigIntAsBoolArraySized(value : BigInt, numBits : Int) : Bool[] {
        let values = BigIntAsBoolArray(value);
        let n = Length(values);

        return n >= numBits ? values[...numBits - 1] | Padded(-numBits, false, values);
    }

    /// # Summary
    /// An implementation for `CNOT` that when controlled using a single control uses
    /// a helper qubit and uses `ApplyAnd` to reduce the T-count to 4 instead of 7.
    internal operation ApplyLowTCNOT(a : Qubit, b : Qubit) : Unit is Adj+Ctl {
        body (...) {
            CNOT(a, b);
        }

        adjoint self;

        controlled (ctls, ...) {
            // In this application this operation is used in a way that
            // it is controlled by at most one qubit.
            Fact(Length(ctls) <= 1, "At most one control line allowed");

            if IsEmpty(ctls) {
                CNOT(a, b);
            } else {
                use q = Qubit();
                within {
                    ApplyAnd(Head(ctls), a, q);
                } apply {
                    CNOT(q, b);
                }
            }
        }

        adjoint controlled self;
    }

	/// # Summary
    /// Performs greater-than-or-equals comparison to a constant.
    ///
    /// # Description
    /// Toggles output qubit `target` if and only if input register `x`
    /// is greater than or equal to `c`.
    ///
    /// # Input
    /// ## c
    /// Constant value for comparison.
    /// ## x
    /// Quantum register to compare against.
    /// ## target
    /// Target qubit for comparison result.
    ///
    /// # Reference
    /// This construction is described in [Lemma 3, arXiv:2201.10200]
    operation CompareGreaterThanOrEqualConstant(c : BigInt, x : LittleEndian, target : Qubit)
    : Unit is Adj+Ctl {
        let bitWidth = Length(x!);

        if c == 0L {
            X(target);
        } elif c >= PowL(2L, bitWidth) {
            // do nothing
        } elif c == PowL(2L, bitWidth - 1) {
            ApplyLowTCNOT(Tail(x!), target);
        } else {
            // normalize constant
            let l = NTrailingZeroes(c);

            let cNormalized = c >>> l;
            let xNormalized = x![l...];
            let bitWidthNormalized = Length(xNormalized);
            let gates = Rest(BigIntAsBoolArraySized(cNormalized, bitWidthNormalized));

            use qs = Qubit[bitWidthNormalized - 1];
            let cs1 = [Head(xNormalized)] + Most(qs);
            let cs2 = Rest(xNormalized);

            within {
                for (c1, c2, t, gateType) in Zipped4(cs1, cs2, qs, gates) {
                    (gateType ? ApplyAnd | ApplyOr)(c1, c2, t);
                }
            } apply {
                ApplyLowTCNOT(Tail(qs), target);
            }
        }
    }

    /// # Summary
    /// Internal operation used in the implementation of GreaterThanOrEqualConstant.
    internal operation ApplyOr(control1 : Qubit, control2 : Qubit, target : Qubit) : Unit is Adj+Ctl {
        within {
            ApplyToEachA(X, [control1, control2]);
        } apply {
            ApplyAnd(control1, control2, target);
            X(target);
        }
    }
}