// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "src/lib/Renderer.sol";

contract RendererTest is Test {
    function testRenderOne() public {
        string memory minSvg = vm.readFile("resources/RIP.prod.min.svg");
        string memory svg = Renderer.renderSvg(
            hex"965f12d657ee47de669b9b94edcc47bbab9b886943233e46c81af970d72b6641",
            2222222,
            9999,
            101,
            "Vitalik.eth",
            10 ether + 12 ether / 100,
            800_000 ether
        );
        assertEq(abi.encodePacked(minSvg), abi.encodePacked(svg));
    }

    function testTransformUint() public {
        assertEq(
            abi.encodePacked("22"),
            abi.encodePacked(Renderer._transformUint256(22))
        );
        assertEq(
            abi.encodePacked("222"),
            abi.encodePacked(Renderer._transformUint256(222))
        );
        assertEq(
            abi.encodePacked("1,026"),
            abi.encodePacked(Renderer._transformUint256(1026))
        );
        assertEq(
            abi.encodePacked("2,222"),
            abi.encodePacked(Renderer._transformUint256(2222))
        );
        assertEq(
            abi.encodePacked("10,006"),
            abi.encodePacked(Renderer._transformUint256(10006))
        );
        assertEq(
            abi.encodePacked("222,222"),
            abi.encodePacked(Renderer._transformUint256(222222))
        );
        assertEq(
            abi.encodePacked("2,222,222"),
            abi.encodePacked(Renderer._transformUint256(2222222))
        );
        assertEq(
            abi.encodePacked("2,002,002"),
            abi.encodePacked(Renderer._transformUint256(2002002))
        );
        assertEq(
            abi.encodePacked("22M"),
            abi.encodePacked(Renderer._transformUint256(22222222))
        );
        assertEq(
            abi.encodePacked("222M"),
            abi.encodePacked(Renderer._transformUint256(222222222))
        );
        assertEq(
            abi.encodePacked("2,222M"),
            abi.encodePacked(Renderer._transformUint256(2222222222))
        );
        assertEq(
            abi.encodePacked("22,222M"),
            abi.encodePacked(Renderer._transformUint256(22222222222))
        );
        assertEq(
            abi.encodePacked("20,002M"),
            abi.encodePacked(Renderer._transformUint256(20002222222))
        );
        assertEq(
            abi.encodePacked("222B"),
            abi.encodePacked(Renderer._transformUint256(222222222222))
        );
        assertEq(
            abi.encodePacked("2,222B"),
            abi.encodePacked(Renderer._transformUint256(2222222222222))
        );
        assertEq(
            abi.encodePacked("22,222B"),
            abi.encodePacked(Renderer._transformUint256(22222222222222))
        );
        assertEq(
            abi.encodePacked("222,222B"),
            abi.encodePacked(Renderer._transformUint256(222222222222222))
        );
        vm.expectRevert();
        Renderer._transformUint256(2222222222222222);
    }

    function testTranformWeiToDecimal2() public {
        assertEq(
            abi.encodePacked("0.10"),
            abi.encodePacked(Renderer._tranformWeiToDecimal2(1 ether / 10))
        );
        assertEq(
            abi.encodePacked("0.01"),
            abi.encodePacked(Renderer._tranformWeiToDecimal2(1 ether / 100))
        );
        assertEq(
            abi.encodePacked("1.00"),
            abi.encodePacked(Renderer._tranformWeiToDecimal2(1 ether))
        );

        assertEq(
            abi.encodePacked("1.01"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(1 ether / 100 + 1 ether)
            )
        );
        assertEq(
            abi.encodePacked("1.10"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(1 ether / 10 + 1 ether)
            )
        );
        assertEq(
            abi.encodePacked("1.11"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(
                    1 ether + 1 ether / 10 + 1 ether / 100
                )
            )
        );
        assertEq(
            abi.encodePacked("10.11"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(
                    10 ether + 1 ether / 10 + 1 ether / 100
                )
            )
        );
        assertEq(
            abi.encodePacked("10.01"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(10 ether + 1 ether / 100)
            )
        );
        assertEq(
            abi.encodePacked("100"),
            abi.encodePacked(
                Renderer._tranformWeiToDecimal2(
                    100 ether + 1 ether / 10 + 1 ether / 100
                )
            )
        );
    }

    function testCompressUtf8() public {
        assertEq(
            abi.encodePacked(Renderer._compressUtf8("@1234567890abcdefgh")),
            abi.encodePacked(unicode"@1234…bcdefgh")
        );
        assertEq(
            abi.encodePacked(Renderer._compressUtf8("vitalik.eth")),
            abi.encodePacked("vitalik.eth")
        );
        assertEq(
            abi.encodePacked(Renderer._compressUtf8("Rekooooooooo.cyber")),
            abi.encodePacked(unicode"Rekoo…o.cyber")
        );
        assertEq(
            abi.encodePacked(
                Renderer._compressUtf8(unicode"通用汽车&巨大的泵.eth")
            ),
            abi.encodePacked(unicode"通用汽车&…大的泵.eth")
        );
    }

    function testTransformBytes32Seed() public {
        assertEq(
            abi.encodePacked(
                "0x965f12d657ee",
                unicode"…",
                "33e46c81af970d72b6641"
            ),
            abi.encodePacked(
                Renderer._transformBytes32Seed(
                    hex"965f12d657ee47de669b9b94edcc47bbab9b886943233e46c81af970d72b6641"
                )
            )
        );
        assertEq(
            abi.encodePacked(
                "0x000000000000",
                unicode"…",
                "000000000000000001e62"
            ),
            abi.encodePacked(
                Renderer._transformBytes32Seed(
                    hex"0000000000000000000000000000000000000000000000000000000000001e62"
                )
            )
        );
    }

    function testRenderTrait() public {
        string memory traits = Renderer.renderTrait(
            hex"965f12d657ee47de669b9b94edcc47bbab9b886943233e46c81af970d72b6641",
            2222222,
            9999,
            101,
            0x1E18EEEEeeeeEeEeEEEeEEEeEEeeEeeeeEeed8e5,
            "vitalik.eth",
            222222 * 10 ** 18,
            222222 * 10 ** 18
        );
        assertEq(
            abi.encodePacked(traits),
            abi.encodePacked(
                '[{"trait_type": "Seed", "value": "0x965f12d657ee47de669b9b94edcc47bbab9b886943233e46c81af970d72b6641"},{"trait_type": "Life Score", "value": 2222222},{"trait_type": "Round", "value": 9999},{"trait_type": "Age", "value": 101},{"trait_type": "Creator", "value": "0x1e18eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed8e5"},{"trait_type": "CreatorName", "value": "vitalik.eth"},{"trait_type": "Reward", "value": 222222000000000000000000},{"trait_type": "Cost", "value": 222222000000000000000000}]'
            )
        );
    }
}
