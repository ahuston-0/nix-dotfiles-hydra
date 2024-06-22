{ lib, ... }:
{
  # create rad-dev namespace for lib
  rad-dev = rec {
    systems = import ./systems.nix { inherit lib; };

    # any(), but checks if any value in the list is true
    #
    # args:
    # n: list of booleans
    #
    # type:
    # anyBool:: [bool] -> bool
    anyBool = lib.any (n: n);

    # pulls a value out of an attrset and converts it to a list
    #
    # args:
    # attr: attribute to search for in an attrset
    # set: attrset to search
    #
    # type:
    # mapGetAttr :: String -> AttrSet -> [Any]
    mapGetAttr = attr: set: lib.mapAttrsToList (_: attrset: lib.getAttr attr attrset) set;

    # gets list of files and directories inside of a directory
    #
    # args:
    # base: base path to search
    # dir: directory to get files from
    #
    # type:
    # ls :: Path -> String -> [String]
    ls = dir: lib.attrNames (builtins.readDir dir);

    # gets list of directories inside of a given directory
    #
    # args:
    # base: base path to search
    # dir: directory to get files from
    #
    # type:
    # lsdir :: Path -> String -> [String]
    lsdir =
      dir:
      lib.optionals (builtins.pathExists dir) (
        lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
      );

    # return full paths of all files in a directory
    #
    # args:
    # base: base path to search
    # dir: path to get files from
    #
    # type:
    # fileList :: Path -> String -> [Path]
    fileList = dir: map (file: dir + "/${file}") (ls dir);

    # Given a attrset of images and a function which generates an image spec,
    # generates a set of containers (although this could in theory be used for
    # other things... I'd like to see people try)
    #
    # container set must be in the below format
    # { container-name = {image = "image-uri"; scale = n;}; }
    # where image-uri gets passed in to the container-spec function as a custom
    # parameter, and scale is an integer that generates the containers
    #
    # container-spec must be a function which accepts one parameter (the
    # container name) and ideally returns an oci-compliant container.
    #
    # args:
    # containers: an AttrSet which specifies the imageUri and scale of each
    #   container
    # container-spec: a function which produces an oci-compliant container spec
    #
    # type:
    # AttrSet -> (AttrSet -> AttrSet) -> AttrSet
    createTemplatedContainers =
      containers: container-spec:
      builtins.listToAttrs (
        lib.flatten (
          lib.mapAttrsToList (
            name: value:
            (map (num: {
              name = "${name}-${parseInt num}";
              value = container-spec value.image;
            }) (lib.lists.range 1 value.scale))
          ) containers
        )
      );

    # Converts an integer into a string
    #
    # Given that trying to do this the way you'd do it in languages like python
    # ("str" + int) causes the program to error out, I assume this is some sort
    # of cardinal sin of nix. However, I want templated docker containers so
    # here we are.
    #
    # Fun fact: if you want to parse a negative number (I know, scary right?),
    # you first need to surround it in parentheses (ie. parseInt (-1000)) as nix
    # interprets negative numbers as a function and will think you're trying to
    # do some really weird function application magic if you try to call this
    # normally (ie. parseInt -1000).
    #
    # args:
    # num: an integer to convert
    #
    # type:
    # parseInt :: Integer -> String
    parseInt =
      num:
      let
        digits = "0123456789";
        mod = num: (lib.trivial.mod num 10);
      in
      if num > 9 then
        ((parseInt (builtins.div num 10)) + (lib.substring (mod num) 1 digits))
      else if num < 0 then
        "-" + (parseInt (builtins.mul num (-1)))
      else
        lib.substring (mod num) 1 digits;
  };

}
