// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EMPTY_UID} from "@eas/contracts/Common.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IProfileRegistry} from "../interfaces/IProfileRegistry.sol";
import {IScrollBadgeResolver} from "../interfaces/IScrollBadgeResolver.sol";
import {MAX_ATTACHED_BADGE_NUM} from "../Common.sol";
import {BadgeCountReached, InvalidBadge, LengthMismatch, Unauthorized, TokenNotOwnedByUser} from "../Errors.sol";

contract Profile is Initializable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*************
     * Constants *
     *************/

    /// @notice The address of `ScrollBadgeResolver` contract.
    address public immutable resolver;

    /***********
     * Structs *
     ***********/

    /// @dev The struct holding profile avatar information.
    /// @param token The address of ERC721 token.
    /// @param tokenId The token id.
    struct Avatar {
        address token;
        uint256 tokenId;
    }

    /*************
     * Variables *
     *************/

    /// @notice The address of profile registry.
    address public registry;

    /// @notice The address of profile owner.
    address public owner;

    /// @notice The name of the profile.
    string public username;

    /// @notice The profile avatar information.
    Avatar public avatar;

    /// @dev The list of uids for attached badges.
    bytes32[] private uids;

    /// @dev Position of the value in the `uids` array, plus 1
    //  because index 0 means a value is not in the set.
    mapping(bytes32 => uint256) indexes;

    /// @dev The unique index for the order of all attached badges (including invalid ones).
    /// Assume the actual order of the badges are: `p[1], p[2], ..., p[n]` and let `a[i]` be
    /// the number of `j` such that `i < j` and `p[i] > p[j]`. Then, the index is defined as:
    ///     `index = a[1] * (n-1)! + a[2] * (n-2)! + ... + a[n-1] * 1! + a[n] * 0!`
    ///
    /// see here for more details: https://www.cnblogs.com/sinkinben/p/15847869.html
    uint256 private badgeOrderEncoding;

    /*************
     * Modifiers *
     *************/

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @param resolver_ The address of `ScrollBadgeResolver` contract.
    constructor(address resolver_) {
        resolver = resolver_;
        _disableInitializers();
    }

    /// @notice Initialize the storage of this contract.
    /// @param owner_ The address of profile owner.
    /// @param username_ The name of the profile.
    function initialize(address owner_, string memory username_) external initializer {
        registry = msg.sender;
        owner = owner_;
        username = username_;

        IProfileRegistry(msg.sender).registerUsername(username_);
    }

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Return the attestation information for the given badge uid.
    /// @param uid The badge uid to query.
    function getAndValidateBadge(bytes32 uid) public view returns (Attestation memory) {
        Attestation memory badge = IScrollBadgeResolver(resolver).getAndValidateBadge(uid);

        if (badge.recipient != owner) {
            revert InvalidBadge(badge.uid);
        }

        return badge;
    }

    /// @notice Check whether a badge is valid.
    /// @param uid The badge uid to query.
    function isBadgeValid(bytes32 uid) public view returns (bool) {
        try this.getAndValidateBadge(uid) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Return the uid list of all attached badges, including invalid ones.
    function getAttachedBadges() external view returns (bytes32[] memory) {
        return uids;
    }

    /// @notice Return the orders of all attached badges, including invalid ones.
    function getBadgeOrder() external view returns (uint256[] memory) {
        return _decodeOrder(badgeOrderEncoding, uids.length);
    }

    /// @notice Return the list of valid badge uids.
    function getValidBadges() external view returns (bytes32[] memory) {
        bytes32[] memory _uids = uids;
        uint256 isValid;
        uint256 length;

        for (uint256 i = 0; i < _uids.length; i++) {
            if (isBadgeValid(_uids[i])) {
                length++;
                isValid |= 1 << i;
            }
        }

        bytes32[] memory result = new bytes32[](length);
        length = 0;
        for (uint256 i = 0; i < _uids.length; i++) {
            if (((isValid >> i) & 1) == 1) {
                result[length++] = _uids[i];
            }
        }

        return result;
    }

    /// @notice Return the token URI for profile avatar.
    function getAvatar() external view returns (string memory) {
        Avatar memory _avatar = avatar;
        if (IERC721(_avatar.token).ownerOf(_avatar.tokenId) == owner) {
            try IERC721Metadata(_avatar.token).tokenURI(_avatar.tokenId) returns (string memory uri) {
                return uri;
            } catch {
                // no logic here
            }
        }
        return IProfileRegistry(registry).getDefaultProfileAvatar();
    }

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Attach a list of badges to this profile.
    /// @param _uids The list of badge uids to attach.
    function attach(bytes32[] memory _uids) external onlyOwner {
        for (uint256 i = 0; i < _uids.length; i++) {
            _attachOne(_uids[i]);
        }
    }

    /// @notice Attach one badge to this profile.
    /// @param _uid The badge uid to attach.
    function attachOne(bytes32 _uid) external onlyOwner {
        _attachOne(_uid);
    }

    /// @notice Detach a list of badges to this profile.
    /// @param _uids The list of badge uids to detach.
    function detach(bytes32[] memory _uids) external onlyOwner {
        for (uint256 i = 0; i < _uids.length; i++) {
            _detachOne(_uids[i]);
        }
    }

    /// @notice Reorder attached badges.
    /// @dev The given order should be a permutation of `1` to `uids.length`, and `_orders[i]`
    ///      means `uids[i]` should be put in `_orders[i]`-th place.
    ///
    /// @param _orders The order of the badges.
    function reorderBadges(uint256[] memory _orders) external onlyOwner {
        if (_orders.length != uids.length) revert LengthMismatch();

        badgeOrderEncoding = _encodeOrder(_orders);
    }

    /// @notice Change the username.
    /// @param newUsername The new username.
    function changeUsername(string memory newUsername) external onlyOwner {
        address _registry = registry;
        IProfileRegistry(_registry).unregisterUsername(username);
        IProfileRegistry(_registry).registerUsername(newUsername);
        username = newUsername;
    }

    /// @notice Change the avatar.
    /// @param token The address of ERC721 token.
    /// @param tokenId The token id.
    function changeAvatar(address token, uint256 tokenId) external onlyOwner {
        if (IERC721(token).ownerOf(tokenId) != owner) {
            revert TokenNotOwnedByUser(token, tokenId);
        }

        avatar = Avatar(token, tokenId);
    }

    /**********************
     * Internal Functions *
     **********************/

    /// @dev Internal function to attach one batch to this profile.
    /// @param uid The badge uid to attach.
    function _attachOne(bytes32 uid) private {
        if (indexes[uid] > 0) return;
        getAndValidateBadge(uid); // validate

        uint256 numAttached = uids.length + 1;
        if (numAttached > MAX_ATTACHED_BADGE_NUM) {
            revert BadgeCountReached();
        }
        uids.push(uid);
        indexes[uid] = numAttached;
    }

    /// @dev Internal function to detach one batch from this profile.
    /// @param uid The badge uid to detach.
    function _detachOne(bytes32 uid) private {
        uint256 valueIndex = indexes[uid];
        if (valueIndex == 0) return;

        uint256 length = uids.length;
        uint256[] memory _oldOrders = _decodeOrder(badgeOrderEncoding, length);
        uint256 toDeleteIndex = valueIndex - 1;
        uint256 lastIndex = length - 1;
        uint256 deletedOrder = _oldOrders[toDeleteIndex];
        if (lastIndex != toDeleteIndex) {
            bytes32 lastValue = uids[lastIndex];

            // Move the last value to the index where the value to delete is
            uids[toDeleteIndex] = lastValue;
            _oldOrders[toDeleteIndex] = _oldOrders[lastIndex];
            // Update the index for the moved value
            indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
        }

        uids.pop();
        delete indexes[uid];

        uint256[] memory _newOrders = new uint256[](lastIndex);
        for (uint256 i = 0; i < lastIndex; i++) {
            _newOrders[i] = _oldOrders[i];
            if (_newOrders[i] > deletedOrder) {
                _newOrders[i] -= 1;
            }
        }
        badgeOrderEncoding = _encodeOrder(_newOrders);
    }

    /// @dev Internal function to encode order array to an integer.
    ///
    /// Caller should make sure `factorial(orders.length)` does not exceed `uint256.max`.
    /// @return encoding The expected encoding in range `[0, factorial(orders.length))`
    function _encodeOrder(uint256[] memory orders) internal pure returns (uint256 encoding) {
        uint256 n = orders.length;
        uint256[] memory fact = new uint256[](n);
        unchecked {
            fact[0] = 1;
            for (uint256 i = 1; i < n; i++) {
                fact[i] = fact[i - 1] * i;
            }

            for (uint256 i = 0; i < n; i++) {
                uint256 cnt;
                for (uint256 j = i + 1; j < n; j++) {
                    if (orders[j] < orders[i]) cnt += 1;
                }
                encoding += fact[n - i - 1] * cnt;
            }
        }
    }

    /// @dev Internal function to decode order encoding to order array.
    function _decodeOrder(uint256 encoding, uint256 n) internal pure returns (uint256[] memory orders) {
        orders = new uint256[](n);
        if (n == 0) return orders;

        uint256[] memory fact = new uint256[](n);
        uint256[] memory nums = new uint256[](n);
        unchecked {
            nums[0] = fact[0] = 1;
            for (uint256 i = 1; i < n; i++) {
                fact[i] = fact[i - 1] * i;
                nums[i] = i + 1;
            }

            for (uint256 i = 0; i < n; i++) {
                uint256 cnt = encoding / fact[n - i - 1];
                orders[i] = nums[cnt];
                for (uint256 j = cnt; j + 1 < n - i; j++) {
                    nums[j] = nums[j + 1];
                }
                encoding -= cnt * fact[n - i - 1];
            }
        }
    }
}
